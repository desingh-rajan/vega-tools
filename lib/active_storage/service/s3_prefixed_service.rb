# frozen_string_literal: true

require "active_storage/service/s3_service"

module ActiveStorage
  class Service::S3PrefixedService < Service::S3Service
    def initialize(bucket:, prefix:, **options)
      @prefix = prefix.to_s.chomp("/")
      @prefix = "#{@prefix}/" if @prefix.present?
      super(bucket: bucket, **options)
    end

    private

    def object_for(key)
      bucket.object("#{@prefix}#{key}")
    end

    # Override to generate meaningful keys with file extensions
    # Format: products/{product_id}/{filename}.webp
    def generate_key_for(io, filename:, content_type:, **options)
      # Check if custom key is provided in metadata
      if options[:metadata].is_a?(Hash) && options[:metadata][:custom_key]
        return options[:metadata][:custom_key]
      end

      # Default behavior with extension
      ext = File.extname(filename.to_s)
      ext = content_type_to_extension(content_type) if ext.blank?
      "#{SecureRandom.base36(28)}#{ext}"
    end

    def content_type_to_extension(content_type)
      case content_type
      when "image/webp" then ".webp"
      when "image/jpeg", "image/jpg" then ".jpg"
      when "image/png" then ".png"
      when "image/gif" then ".gif"
      else ""
      end
    end
  end
end
