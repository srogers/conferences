module PresentationsHelper

  def format_and_date(publication)
    if publication.url.present?
      link_to(publication.format, publication.url) + ", #{ publication.published_on.year }"
    else
      "#{ publication.format }, #{ publication.published_on.year }"
    end
  end

  def google_safe(text)
    searchable_title = text.gsub(" ", "+")                        # Google uses pluses for spaces
    searchable_title = searchable_title.delete("^a-zA-Z0-9+\-")   # Add the first speaker as an additional term
    return searchable_title
  end

  # Builds a URL for Google Search that will search on the title and first presenter, to provide an easy way
  # to find copies of the presentation online
  def google_search_url(presentation)
    url = "https://www.google.com/search?&q=%22#{ google_safe(presentation.name) }%22"
    url += "+%22#{ google_safe(presentation.speakers.first.name) }%22" if presentation.speakers.present?
    return url
  end
end
