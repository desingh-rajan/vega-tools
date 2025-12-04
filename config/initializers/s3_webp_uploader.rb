S3WebpUploader.configure do |config|
  config.bucket = ENV.fetch("S3_BUCKET", "tstack-desingh")
  config.region = ENV.fetch("S3_REGION", "ap-south-1")

  # Map Rails environments to S3 folder names
  env_folder = { "development" => "dev", "production" => "prod", "test" => "test" }
  app_name = ENV.fetch("S3_APP_NAME", "vega-tools")
  config.prefix = "#{app_name}/#{env_folder.fetch(Rails.env, Rails.env)}/images"

  # AWS credentials auto-loaded from Rails credentials (aws.access_key_id, aws.secret_access_key)
end
