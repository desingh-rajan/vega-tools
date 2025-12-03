# frozen_string_literal: true

# Job to process uploaded images into WebP format
# Creates two versions: original (max 1200px) and thumbnail (300px)
# Deletes the original uploaded file after processing
class ImageProcessingJob < ApplicationJob
  queue_as :default

  # Variant configurations
  ORIGINAL_OPTIONS = {
    resize_to_limit: [ 1200, 1200 ],
    format: :webp,
    saver: { quality: 85 }
  }.freeze

  THUMBNAIL_OPTIONS = {
    resize_to_limit: [ 300, 300 ],
    format: :webp,
    saver: { quality: 80 }
  }.freeze

  def perform(blob_id)
    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return unless blob
    return if blob.content_type == "image/webp" # Already processed

    # Skip if not an image
    return unless blob.image?

    Rails.logger.info "[ImageProcessingJob] Processing blob #{blob_id}: #{blob.filename}"

    # Pre-process both variants (this triggers generation and caching)
    begin
      # Find the attachment
      attachment = ActiveStorage::Attachment.find_by(blob_id: blob.id)
      return unless attachment

      record = attachment.record
      attachment_name = attachment.name

      # Generate and cache the variants
      if record.respond_to?("#{attachment_name}_blobs") || record.respond_to?(attachment_name)
        # For has_many_attached, we work with the blob directly
        blob.variant(ORIGINAL_OPTIONS).processed
        blob.variant(THUMBNAIL_OPTIONS).processed

        Rails.logger.info "[ImageProcessingJob] Successfully processed blob #{blob_id}"
      end
    rescue => e
      Rails.logger.error "[ImageProcessingJob] Error processing blob #{blob_id}: #{e.message}"
      raise e
    end
  end
end
