# frozen_string_literal: true

# Helper module for converting images to WebP format locally
# Used during seeding to upload already-processed images
module ImageConverter
  extend self

  ORIGINAL_SIZE = [ 1200, 1200 ].freeze
  THUMBNAIL_SIZE = [ 300, 300 ].freeze
  WEBP_QUALITY = 85

  # Convert an image file to WebP format
  # Returns a hash with :original and :thumbnail temp files
  def convert_to_webp(source_path)
    return nil unless File.exist?(source_path)
    return nil unless image_file?(source_path)

    require "vips"

    # Load the source image
    image = Vips::Image.new_from_file(source_path, access: :sequential)

    # Create original (resized to max dimensions)
    original = resize_image(image, ORIGINAL_SIZE)
    original_file = create_temp_webp(original, "original")

    # Create thumbnail
    thumbnail = resize_image(image, THUMBNAIL_SIZE)
    thumbnail_file = create_temp_webp(thumbnail, "thumb")

    {
      original: original_file,
      thumbnail: thumbnail_file,
      original_filename: webp_filename(source_path, "original"),
      thumbnail_filename: webp_filename(source_path, "thumb")
    }
  rescue => e
    Rails.logger.error "[ImageConverter] Failed to convert #{source_path}: #{e.message}"
    nil
  end

  # Convert and attach images to a record
  # Usage: ImageConverter.attach_webp(product, :images, "/path/to/image.jpg")
  def attach_webp(record, attachment_name, source_path)
    converted = convert_to_webp(source_path)
    return false unless converted

    attachments = []

    # Attach original
    attachments << {
      io: converted[:original],
      filename: converted[:original_filename],
      content_type: "image/webp"
    }

    record.send(attachment_name).attach(attachments)

    # Clean up temp files
    converted[:original].close
    converted[:thumbnail].close

    true
  rescue => e
    Rails.logger.error "[ImageConverter] Failed to attach #{source_path}: #{e.message}"
    false
  end

  # Batch convert multiple images
  # Returns array of hashes ready for attach
  def batch_convert(source_paths)
    source_paths.filter_map do |path|
      converted = convert_to_webp(path)
      next unless converted

      {
        io: converted[:original],
        filename: converted[:original_filename],
        content_type: "image/webp",
        _temp_files: [ converted[:original], converted[:thumbnail] ]
      }
    end
  end

  private

  def image_file?(path)
    ext = File.extname(path).downcase
    %w[.jpg .jpeg .png .webp .gif .bmp .tiff].include?(ext)
  end

  def resize_image(image, max_dimensions)
    max_width, max_height = max_dimensions

    # Calculate scale factor
    scale = [ max_width.to_f / image.width, max_height.to_f / image.height ].min

    # Only resize if image is larger than max dimensions
    if scale < 1
      image.resize(scale)
    else
      image
    end
  end

  def create_temp_webp(image, suffix)
    temp_file = Tempfile.new([ "converted_#{suffix}_", ".webp" ])
    image.webpsave(temp_file.path, Q: WEBP_QUALITY)
    temp_file.rewind
    temp_file
  end

  def webp_filename(source_path, suffix)
    base = File.basename(source_path, ".*")
    "#{base}_#{suffix}.webp"
  end
end
