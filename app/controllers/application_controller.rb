class ApplicationController < ActionController::Base

  include Sortability  # most controllers use it, and we need to surface a helper method from it below

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_raven_context

  before_action :redirect_to_canonical_domain

  helper_method :current_user_session, :current_user    # defined below
  helper_method :params_with_sort                       # defined in Sortability concern which is primarily for controllers - but views need this method

  private

  GDPR_COUNTRIES = [
      "AT", # Austria
      "BE", # Belgium
      "BG", # Bulgaria
      "HR", # Croatia
      "CY", # Republic of Cyprus
      "CZ", # Czech Republic
      "DK", # Denmark
      "EE", # Estonia
      "FI", # Finland
      "FR", # France
      "DE", # Germany
      "GR", # Greece
      "HU", # Hungary
      "IE", # Ireland
      "IT", # Italy
      "LV", # Latvia
      "LT", # Lithuania
      "LU", # Luxembourg
      "MT", # Malta
      "NL", # Netherlands
      "PL", # Poland
      "PT", # Portugal
      "RO", # Romania
      "SK", # Slovakia
      "SI", # Slovenia
      "ES", # Spain
      "SE", # Sweden
      "GB", # United Kingdom
  ]

  def set_raven_context
    Raven.user_context(id: current_user&.id)
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end

  # If any request makes it to the app with some other domain, redirect to the "real" one.
  # This should behave correctly across a domain name change.
  def redirect_to_canonical_domain
    return true if Rails.env.test?

    if request.host != ENV['MAIL_HOST'].split(':').first # MAIL_HOST contains the port in development
      redirect_to "#{request.protocol}#{ENV['MAIL_HOST']}#{request.fullpath}", :status => :moved_permanently
    else
      return true
    end
  end

  # Converts a two character code like "US" to full name "United States"
  def country_name(country_code)
    country_object = ISO3166::Country[country_code]
    country_object.translations[I18n.locale.to_s] || country_object.name
  end

  # Get the two character code like "US" from the full name "United States"
  def country_code(country_name)
    country = ISO3166::Country.find_country_by_name(country_name)
    country&.alpha2
  end

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to login_url
      return false
    end
  end

  def require_no_user
    if current_user
      flash[:notice] = "You must be logged out to access this page"
      redirect_to root_path
      return false
    end
  end

  # This is part of an escalating sequence - require_editor requires editor or higher role
  def require_editor
    unless current_user && (current_user.editor? || current_user.admin?)
      store_location
      flash[:notice] = "You do not have permissions to access that page"
      redirect_to root_path
      return false
    end
  end

  def require_admin
    unless current_user && current_user.admin?
      store_location
      flash[:notice] = "You do not have permissions to access that page"
      redirect_to root_path
      return false
    end
  end

  def store_location
    session[:return_to] = request.url
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  rescue_from CanCan::AccessDenied do |exception|
    logger.warn "ApplicationController handled AccessDenied for user #{ current_user.try(:id) } - #{ current_user.try(:name) } - #{ current_user.try(:role_name)}"
    flash[:notice] = "You do not have permissions to access that page"
    redirect_to root_url
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    logger.warn "ApplicationController handled failed find: #{ exception }"
    begin
      respond_to do |format|
        format.html do
          flash[:notice] = "Couldn't find that information"
          redirect_to root_url
        end
        format.json do
          render :json => { :error => 'not found', status: 404 }
        end
      end
    # this can happen often with "robot" URLs like /events/favicon.ico - which raises ActiveRecord::RecordNotFound, then
    # raises UnknownFormat on .ico - so we wind up here
    rescue ActionController::UnknownFormat
      logger.warn "ApplicationController handled unknown format "
      flash[:notice] = "Couldn't find that information"
      redirect_to root_url
    end
  end

end
