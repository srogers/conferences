CarrierWave.configure do |config|
  # Use local storage if in development or test
  if Rails.env.development?
    config.storage = :file
  elsif Rails.env.test? || Rails.env.cucumber?
    config.storage = :file
    config.enable_processing = false
  else
    config.fog_provider    = 'fog/aws'                              # Only using AWS
    config.fog_credentials = {
        :provider               => 'AWS',                           # required
        :aws_access_key_id      => ENV['S3_KEY'],                   # required
        :aws_secret_access_key  => ENV['S3_SECRET_KEY'],            # required
        :region                 => 'us-east-1'                      # optional, defaults to 'us-east-1'
    }
    config.fog_directory  = ENV['S3_BUCKET_NAME']                   # required
    #config.fog_host       = 'https://assets.example.com'           # optional, defaults to nil
    config.fog_public     = false                                   # optional, defaults to true
    config.fog_attributes = {'Cache-Control'=>"max-age=#{365.day.to_i}"}  # optional, defaults to {}
    config.cache_dir      = "#{Rails.root}/tmp/uploads"
  end
end
