class Conference < ApplicationRecord

  require 'states'  # seems like it shouldn't be necessary to load this explicitly, but it is
  include States

  belongs_to  :organizer
  belongs_to  :creator,   class_name: "User"

  has_many :presentations                       # currently, conferences with presentations can't be destroyed
  has_many :speakers, through: :presentations

  has_many :conference_users,                   :dependent => :destroy
  has_many :users, through: :conference_users

  validates :name, :organizer_id, :start_date, :end_date, presence: true
  validate  :starts_before_ending
  validate  :us_state_existence

  before_validation :set_default_name

  extend FriendlyId
  friendly_id :name, use: :slugged

  def starts_before_ending
    errors.add(:end_date, 'End date has to be after or the same as start date') if start_date.present? && end_date.present? && start_date > end_date
  end

  def us_state_existence
    return true unless country == 'US'
    errors.add(:state, 'Use the standard two-letter postal abbreviation for US states.') unless States::STATES.map{|s| s[0]}.include?(state)
  end

  def set_default_name
    # Usually an adequate name - like "OCON 2015" or "TOS-CON 2018", but not great for special events.
    # When the default name is not great, the user just has to change it.
    self.name = "#{organizer&.abbreviation} #{start_date&.year}" if name.blank?
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

  def location(show_country=false)
    elements = [city.presence, state.presence]
    elements << [country_name.presence] if show_country.to_s == 'full'
    elements << [country.presence] if show_country.to_s == 'short'
    elements.compact.join(', ')
  end

  # This is referenced by itself in conference/index, so it isn't private
  def date_span
    # Using pretty_date here to avoid having to deal with strftime or build a lookup table for month names
    start_text = "#{ ApplicationController.helpers.pretty_date start_date, style: :yearless }"
    if start_date == end_date
      end_text = ", #{ end_date.year}"
    else
      end_text = "#{ end_date.day }, #{ end_date.year }"
      if start_date.month != end_date.month
        end_text = "#{ I18n.l(end_date, format: "%b") } " + end_text
      end
      end_text = "-" + end_text
    end
    return start_text + end_text
  end
end
