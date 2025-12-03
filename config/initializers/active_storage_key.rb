# frozen_string_literal: true

# Customize Active Storage blob key generation to include
# meaningful folder structures and file extensions
#
# Key format: products/{product_id}/{variant}_{timestamp}.webp
# Example: products/42/original_abc123.webp
#          products/42/thumbnail_abc123.webp

Rails.application.config.after_initialize do
  ActiveStorage::Blob.class_eval do
    # Override key generation to include file extension
    def self.generate_unique_secure_token(length: MINIMUM_TOKEN_LENGTH)
      SecureRandom.base36(length)
    end

    # Set key before create to include extension
    before_create :set_key_with_extension

    private

    def set_key_with_extension
      return if key.present? && key.include?(".")

      ext = File.extname(filename.to_s)
      if ext.blank? && content_type.present?
        ext = case content_type
        when "image/webp" then ".webp"
        when "image/jpeg", "image/jpg" then ".jpg"
        when "image/png" then ".png"
        when "image/gif" then ".gif"
        else ""
        end
      end

      # If key already set (from metadata), ensure it has extension
      if key.present?
        self.key = "#{key}#{ext}" unless key.end_with?(ext)
      else
        self.key = "#{self.class.generate_unique_secure_token}#{ext}"
      end
    end
  end
end
