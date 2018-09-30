class PresentationSerializer
  include FastJsonapi::ObjectSerializer

  attributes :name, :parts, :conference_name

  attribute :description do |presentation|
    # presentation.description.truncate(80, separator: ' ')
    # provide a plaintext description
    ActionController::Base.helpers.strip_tags presentation.description.truncate(80, separator: ' ')
  end
end
