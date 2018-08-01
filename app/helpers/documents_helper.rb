module DocumentsHelper

  # Lists the names of the options selected for this document
  def option_text(document)
    elements = []
    elements << ['Conferences']   if document.conferences
    elements << ['Presentations'] if document.presentations
    elements << ['Speakers']      if document.speakers
    elements = ['Default'] if elements.blank?
    return elements.join(', ')
  end
end
