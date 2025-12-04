S3WebpUploader.configure do |config|
  config.bucket = "tstack-desingh"
  config.region = "ap-south-1"
  
  # Map Rails environments to S3 folder names
  env_folder = { "development" => "dev", "production" => "prod", "test" => "test" }
  config.prefix = "vega-tools/#{env_folder.fetch(Rails.env, Rails.env)}/images"

  # AWS credentials auto-loaded from Rails credentials (aws.access_key_id, aws.secret_access_key)
end
