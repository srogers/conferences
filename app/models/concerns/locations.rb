# Defines location-related constants and methods shared by Conference and Presentation
module Locations
  extend ActiveSupport::Concern

  included do

  end

  PHYSICAL = 'Physical'.freeze
  VIRTUAL  = 'Virtual'.freeze
  MULTIPLE = 'Multiple'.freeze
  LOCATION_TYPES = [PHYSICAL, VIRTUAL, MULTIPLE].freeze

  def virtual?
    venue == VIRTUAL
  end

  def multi_venue?
    venue == MULTIPLE
  end

  def us_state_existence
    return true unless country == 'US'                 # ignore foreign states because we can't validate them
    return true if [VIRTUAL, MULTIPLE].include? venue  # allow blank in this case
    state.upcase!
    return true if city.blank?                         # if city is skipped, state can be too - needed for events with sketchy info
    errors.add(:state, 'Use the standard two-letter postal abbreviation for US states.') unless States::STATES.map{|s| s[0]}.include?(state)
  end

  # Uses translations provided by country_select gem to convert the country_code to country name
  def country_name
    if country.present?
      country_object = ISO3166::Country[country]
      country_object.translations[I18n.locale.to_s] || country_object.name
    else
      "n/a"
    end
  end

  # Returns the whole location, in a format that makes sense with the label "Venue:"  Options:
  # :country_format - false, :short, or :full  default = :short
  # :wrapping       - default false, uses &nbsp; as a separator.
  #                   Must be TRUE for PDFs, which don't support entity codes. non-breaking looks better in HTML lists
  # :include_us     - by default, country is omitted unless it is non-US
  def location(options={})
    return venue if [VIRTUAL, MULTIPLE].include? venue
    include_country = options[:include_us] || country != 'US'
    elements = [city.presence, state.presence]
    elements << [country_name.presence] if options[:country_format].to_s == 'full' && include_country
    elements << [country.presence] if options[:country_format].to_s == 'short' && include_country
    elements.compact.join(options[:wrapping] ? ' ': '&nbsp;').html_safe
  end

end
