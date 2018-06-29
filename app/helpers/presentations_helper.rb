module PresentationsHelper

  def format_and_date(publication)
    if publication.url.present?
      link_to(publication.format, publication.url) + ", #{ publication.published_on.year }"
    else
      "#{ publication.format }, #{ publication.published_on.year }"
    end
  end
end
