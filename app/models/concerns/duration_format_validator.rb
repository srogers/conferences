class DurationFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return true if value.blank?                                     # This complicates validation, but it's legit
    return false if value.to_i < 0
    return true if value.to_i.to_s == value                         # Then it's probably a duration in minutes
    return true if value =~             /^[0-9]:[0-5][0-9]$/
    return true if value =~        /^[0-5][0-9]:[0-5][0-9]$/
    return true if value =~  /^[0-9]:[0-5][0-9]:[0-5][0-9]$/
    return true if value =~ /^0[0-9]:[0-5][0-9]:[0-5][0-9]$/        # allow this for the sake of symmetry. value > 9 prob not real

    record.errors.add(attribute, "must be a number in seconds or formatted like hh:mm or hh:mm:ss")
  end
end
