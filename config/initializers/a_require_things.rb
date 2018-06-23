# Require things that are generally used everywhere rather than seeding out requires through files
require 'link_thumbnailer'

# It seems like this shouldn't be necessary, but otherwise the line "storage :fog" in PhotoUploader gets:  uninitialized constant CarrierWave::Storage::Fog
require 'carrierwave/storage/fog'
