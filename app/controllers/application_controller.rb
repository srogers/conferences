class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  helper_method :current_user_session, :current_user

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

  def require_editor
    unless current_user && current_user.editor?
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
    flash[:notice] = "Couldn't find that information"
    redirect_to root_url
  end
end
