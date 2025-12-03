# frozen_string_literal: true

# Service to upload product images directly to S3
# Converts to WebP and creates original + thumbnail versions
#
# Usage:
#   uploader = ProductImageUploader.new(product)
#   uploader.upload(file)  # ActionDispatch::Http::UploadedFile
#   uploader.upload_multiple([file1, file2])
#   uploader.delete_all
#
class ProductImageUploader
  ORIGINAL_MAX_SIZE = 1200
  THUMBNAIL_MAX_SIZE = 300
  WEBP_QUALITY = 85

  attr_reader :product, :s3_client, :bucket, :prefix

  def initialize(product)
    @product = product
    @s3_client = Aws::S3::Client.new(
      region: s3_region,
      access_key_id: Rails.application.credentials.dig(:aws, :access_key_id),
      secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key)
    )
    @bucket = s3_bucket
    @prefix = s3_prefix
  end

  # Upload a single image file
  # Returns the index of the uploaded image
  def upload(file)
    return nil unless valid_image?(file)
    return nil if product.slug.blank?

    index = current_image_count

    # Convert and upload original
    original_file = convert_to_webp(file.tempfile.path, ORIGINAL_MAX_SIZE)
    return nil unless original_file

    original_key = s3_key(:original, index)
    upload_to_s3(original_file, original_key)
    original_file.close

    # Convert and upload thumbnail
    thumbnail_file = convert_to_webp(file.tempfile.path, THUMBNAIL_MAX_SIZE)
    if thumbnail_file
      thumbnail_key = s3_key(:thumbnail, index)
      upload_to_s3(thumbnail_file, thumbnail_key)
      thumbnail_file.close
    end

    # Update image count
    update_image_count(index + 1)

    index
  rescue => e
    Rails.logger.error "[ProductImageUploader] Upload failed: #{e.message}"
    nil
  end

  # Upload multiple images
  def upload_multiple(files)
    files.filter_map { |file| upload(file) }
  end

  # Replace an existing image at a specific index
  # Deletes old image from S3 and uploads new one in its place
  def replace(file, index)
    return nil unless valid_image?(file)
    return nil if product.slug.blank?
    return nil if index < 0 || index >= current_image_count

    # Delete existing images at this index
    delete_from_s3(s3_key(:original, index))
    delete_from_s3(s3_key(:thumbnail, index))

    # Convert and upload new original
    original_file = convert_to_webp(file.tempfile.path, ORIGINAL_MAX_SIZE)
    return nil unless original_file

    original_key = s3_key(:original, index)
    upload_to_s3(original_file, original_key)
    original_file.close

    # Convert and upload new thumbnail
    thumbnail_file = convert_to_webp(file.tempfile.path, THUMBNAIL_MAX_SIZE)
    if thumbnail_file
      thumbnail_key = s3_key(:thumbnail, index)
      upload_to_s3(thumbnail_file, thumbnail_key)
      thumbnail_file.close
    end

    index
  rescue => e
    Rails.logger.error "[ProductImageUploader] Replace failed: #{e.message}"
    nil
  end

  # Delete a specific image by index
  def delete(index)
    delete_from_s3(s3_key(:original, index))
    delete_from_s3(s3_key(:thumbnail, index))

    # Reindex remaining images and update count
    reindex_images_after_delete(index)
  end

  # Delete all images for this product
  def delete_all
    count = current_image_count
    count.times do |i|
      delete_from_s3(s3_key(:original, i))
      delete_from_s3(s3_key(:thumbnail, i))
    end
    update_image_count(0)
  end

  # Check if image exists at index
  def exists?(index = 0)
    head_object(s3_key(:original, index))
  end

  private

  def s3_bucket
    Rails.configuration.x.s3_images_bucket || "tstack-desingh"
  end

  def s3_region
    Rails.configuration.x.s3_images_region || "ap-south-1"
  end

  def s3_prefix
    Rails.configuration.x.s3_images_prefix || "vega-tools/dev/images"
  end

  def s3_key(variant, index)
    suffix = index.zero? ? "" : "_#{index}"
    "#{prefix}/#{product.slug}/#{variant}#{suffix}.webp"
  end

  def current_image_count
    product.specifications&.dig("image_count") || 0
  end

  def update_image_count(count)
    specs = product.specifications || {}
    specs["image_count"] = count
    product.update_columns(specifications: specs, updated_at: Time.current)
  end

  def valid_image?(file)
    return false unless file.respond_to?(:content_type)
    file.content_type&.start_with?("image/")
  end

  def convert_to_webp(source_path, max_size)
    require "vips"

    image = Vips::Image.new_from_file(source_path, access: :sequential)
    scale = [ max_size.to_f / image.width, max_size.to_f / image.height ].min
    resized = scale < 1 ? image.resize(scale) : image

    temp = Tempfile.new([ "webp_", ".webp" ])
    resized.webpsave(temp.path, Q: WEBP_QUALITY)
    temp.rewind
    temp
  rescue => e
    Rails.logger.error "[ProductImageUploader] Conversion failed: #{e.message}"
    nil
  end

  def upload_to_s3(file, key)
    file.rewind if file.respond_to?(:rewind)

    s3_client.put_object(
      bucket: bucket,
      key: key,
      body: file,
      content_type: "image/webp",
      acl: "public-read"
    )
  end

  def delete_from_s3(key)
    s3_client.delete_object(bucket: bucket, key: key)
  rescue Aws::S3::Errors::NoSuchKey
    # Ignore if doesn't exist
  end

  def head_object(key)
    s3_client.head_object(bucket: bucket, key: key)
    true
  rescue Aws::S3::Errors::NotFound
    false
  end

  def reindex_images_after_delete(deleted_index)
    count = current_image_count

    # If not deleting the last image, we need to reindex
    if deleted_index < count - 1
      # Move all images after deleted_index down by 1
      ((deleted_index + 1)...count).each do |i|
        # Copy to new position
        [ :original, :thumbnail ].each do |variant|
          old_key = s3_key(variant, i)
          new_key = s3_key(variant, i - 1)

          begin
            s3_client.copy_object(
              bucket: bucket,
              copy_source: "#{bucket}/#{old_key}",
              key: new_key,
              acl: "public-read"
            )
            delete_from_s3(old_key)
          rescue => e
            Rails.logger.error "[ProductImageUploader] Reindex failed: #{e.message}"
          end
        end
      end
    end

    # Always update the count
    update_image_count(count - 1)
  end
end
