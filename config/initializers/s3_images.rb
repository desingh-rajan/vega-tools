# frozen_string_literal: true

# S3 Images Base URL Configuration
# Images are stored at: {base_url}/{product_slug}/original.webp, thumbnail.webp

Rails.application.configure do
  bucket = "tstack-desingh"
  region = "ap-south-1"

  prefix = case Rails.env
  when "production" then "vega-tools/prod/images"
  when "development" then "vega-tools/dev/images"
  else "vega-tools/test/images"
  end

  config.x.s3_images_base_url = "https://#{bucket}.s3.#{region}.amazonaws.com/#{prefix}"
  config.x.s3_images_bucket = bucket
  config.x.s3_images_prefix = prefix
  config.x.s3_images_region = region
end
