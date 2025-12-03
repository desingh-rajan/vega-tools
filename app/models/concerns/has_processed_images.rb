# frozen_string_literal: true

# Concern for models with processed images (WebP conversion)
# Provides helper methods for accessing original and thumbnail variants
# and automatically queues processing after upload
module HasProcessedImages
  extend ActiveSupport::Concern

  # Variant configurations (same as ImageProcessingJob)
  ORIGINAL_VARIANT = {
    resize_to_limit: [ 1200, 1200 ],
    format: :webp,
    saver: { quality: 85 }
  }.freeze

  THUMBNAIL_VARIANT = {
    resize_to_limit: [ 300, 300 ],
    format: :webp,
    saver: { quality: 80 }
  }.freeze

  MICRO_VARIANT = {
    resize_to_limit: [ 50, 50 ],
    format: :webp,
    saver: { quality: 70 }
  }.freeze

  class_methods do
    # Define processed image methods for an attachment
    # Usage: has_processed_images :images
    def has_processed_images(attachment_name)
      # After commit, queue processing for new attachments
      after_commit do
        attachments = send(attachment_name)
        next unless attachments.attached?

        blobs = attachments.respond_to?(:blobs) ? attachments.blobs : [ attachments.blob ]
        blobs.each do |blob|
          # Only process non-WebP images that haven't been processed
          next if blob.content_type == "image/webp"
          next if blob.metadata["processed"]

          ImageProcessingJob.perform_later(blob.id)
        end
      end

      # Define helper methods for accessing variants
      define_method("#{attachment_name}_original") do |index = 0|
        get_variant(attachment_name, index, ORIGINAL_VARIANT)
      end

      define_method("#{attachment_name}_thumbnail") do |index = 0|
        get_variant(attachment_name, index, THUMBNAIL_VARIANT)
      end

      define_method("#{attachment_name}_micro") do |index = 0|
        get_variant(attachment_name, index, MICRO_VARIANT)
      end

      # Get all thumbnails for has_many_attached
      define_method("#{attachment_name}_all_thumbnails") do
        attachments = send(attachment_name)
        return [] unless attachments.attached?

        if attachments.respond_to?(:map)
          attachments.map { |a| a.variant(THUMBNAIL_VARIANT) }
        else
          [ attachments.variant(THUMBNAIL_VARIANT) ]
        end
      end

      # Get all originals for has_many_attached
      define_method("#{attachment_name}_all_originals") do
        attachments = send(attachment_name)
        return [] unless attachments.attached?

        if attachments.respond_to?(:map)
          attachments.map { |a| a.variant(ORIGINAL_VARIANT) }
        else
          [ attachments.variant(ORIGINAL_VARIANT) ]
        end
      end
    end
  end

  private

  def get_variant(attachment_name, index, variant_options)
    attachments = send(attachment_name)
    return nil unless attachments.attached?

    attachment = if attachments.respond_to?(:[], Integer)
                   attachments[index]
    elsif attachments.respond_to?(:first)
                   index == 0 ? attachments.first : attachments.to_a[index]
    else
                   attachments
    end

    return nil unless attachment

    attachment.variant(variant_options)
  end
end
