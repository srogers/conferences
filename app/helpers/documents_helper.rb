module DocumentsHelper

  # Lists the names of the options selected for this document
  def option_text(document)
    options = document.options
    elements = []
    elements << ['Conferences']   if options[:conferences]
    elements << ['Presentations'] if options[:presentations]
    elements << ['Speakers']      if options[:speakers]
    elements = ['Default'] if elements.blank?
    return elements.join(', ')
  end
end
