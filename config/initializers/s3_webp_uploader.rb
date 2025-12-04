S3WebpUploader.configure do |config|
  config.bucket = "tstack-desingh"
  config.region = "ap-south-1"
  config.prefix = "vega-tools/#{Rails.env}/images"

  # AWS credentials auto-loaded from Rails credentials (aws.access_key_id, aws.secret_access_key)
end
