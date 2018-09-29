class PublicationSerializer
  include FastJsonapi::ObjectSerializer

  attributes :name, :format, :url, :notes, :duration
end
