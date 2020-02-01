# encoding: utf-8

class PhotoUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Let config/initializers/carrierwave.rb choose what kind of storage to use for this uploader based on environment
  # storage :file
  storage :fog if Rails.env.production?

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default image if a photo hasn't been uploaded - for speakers and users
  def default_url(*args)
    #ActionController::Base.helpers.image_tag 'default_user_icon.png', alt: "No Image Provided"   # adding alt text breaks the URL
    #ActionController::Base.helpers.asset_path "default_user_icon.png"                            # This works but seems unnecessary
    "default_user_icon.png"
  end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
