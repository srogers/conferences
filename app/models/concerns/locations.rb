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

  # Returns the whole location, in a format that makes sense with the label  Venue:
  def location(show_country=false)
    return venue if [VIRTUAL, MULTIPLE].include? venue
    elements = [city.presence, state.presence]
    elements << [country_name.presence] if show_country.to_s == 'full'
    elements << [country.presence] if show_country.to_s == 'short'
    elements.compact.join(',&nbsp;').html_safe
  end

end
