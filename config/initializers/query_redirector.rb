# This gets used in routes.rb, so it needs to be defined early.
# It simplifies routing specification for redirects like:
#
#     get "/conferences", to: redirect(QueryRedirector.new("/events"))
#
# and ensures the params are passed along in the redirect.

class QueryRedirector
  def call(params, request)
    uri = URI.parse(request.original_url)
    if uri.query
      "#{@destination}?#{uri.query}"
    else
      @destination
    end
  end

  def initialize(destination)
    @destination = destination
  end
end
