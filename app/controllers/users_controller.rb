class UsersController < ApplicationController

  include Sortability
  include StickyNavigation

  before_action :check_nav_params, only: [:index]
  before_action :require_admin, except: [:new, :create, :supporters, :summary, :events]   # new, create, events, and supporters are open
  before_action :require_user,  only: [:summary]

  def index
    @require_account_approval = Setting.require_account_approval?
    @users = User.includes(:role).order(params_to_sql('>users.sortable_name'))
    if param_context(:needs_approval).present?
      @users = @users.needing_approval.order(:created_at)
    else
      if param_context(:search_term).present?
        term = param_context(:search_term)
        @users = @users.where('users.name ILIKE ? OR users.sortable_name ILIKE ? OR users.email ILIKE ?', "#{term}%", "#{term}%", "%#{term}%")
      end
    end

    @users = @users.page(param_context(:page)).per(param_context(:per))
    repaginate_if_needed(@users)
  end

  # Drives the Supporters page in the top-level menu - which is mostly run by the pages controller, but this item is not static.
  def supporters
    @editors = User.editors.where('show_contributor') # TODO: consider adding sortable_name .order(:sortable_name)
  end

  # finds names for autocomplete
  def names
    # only admins need this so block it to prevent data fishing
    if current_user.admin? && params[:q].present? #&& params[:q][:term].present?
      term =  params[:q]
      # search for first name or last name beginning with the typed characters
      @users = User.select(:id, :name).order('name').where("name ILIKE ? OR name ILIKE ?", term+'%', "% #{ term }%")
      users_count = @users.length
      @users = @users.page(params[:page]).per(params[:per])
      logger.debug "user count = #{ @users.length }"
    else
      @users =[]
    end

    # The result has to be built with the keys in the user data expected by select2
    respond_to do |format|
      format.html { head :ok }
      format.json { render json: { total: users_count, users: @users.map{|u| {id: u.id, text: u.name } } } }
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def summary
    if current_user.admin? && params[:id].present?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
    raise CanCan::AccessDenied unless @user == current_user || current_user.admin?

    # System activity
    @conferences_created = Conference.where(:creator_id => @user.id).count
    @presentations_created = Presentation.where(:creator_id => @user.id).count
    @publications_created = Publication.where(:creator_id => @user.id).count
    @speakers_created = Speaker.where(:creator_id => @user.id).count

    # Personal activity
    @conferences_attended = @user.conferences.order(Arel.sql('start_date DESC'))
    @presentations = @user.user_presentations     # presentations the user is watching
    @notifications = @user.notifications          # notifications sent
  end

  # This action is open, because even non-authenticated users can look at attendance of other users.
  # This might be a little sketchy, because it allows for fishing of user IDs - maybe it should hash the ID?
  def events
    if param_context(:user_id).present?    # asking about somebody else
      param_context(:my_events, false)     # unset this
      @user = User.find param_context(:user_id)
      unless @user.present? && (current_user&.id == @user.id || @user.show_attendance || current_user&.admin?)
        # You can't see it because:  it doesn't exist or it's not you or the user says no, or you're not admin
        flash[:notice] = "No information available."
        redirect_to root_path and return
      end
    elsif !current_user.present?           # asking about self but not logged in
      flash[:notice] = "Log in to see a list of the events you've attended."
      redirect_to root_path and return # non-authenticated user can't ask to see their own events
    else                                   # asking about self when logged in
      param_context(:my_events, true)      # set this for any future chart requests
      logger.debug "BEFORE unset user id param context"
      param_context(:user_id,   'blank')   # unset this
      logger.debug "AFTER unset user id param context"
      @user = current_user
    end

    @conferences = @user.conferences
    @conferences = @conferences.where("conferences.event_type ILIKE ?", param_context(:event_type)) if param_context(:event_type).present?
    @conferences = @conferences.order(Arel.sql('start_date DESC'))
  end

  def edit
    get_roles
    @user = User.find(params[:id])
  end

  def new
    if current_user && !current_user.admin?
      # only admin can create new users directly
      redirect_to root_path and return
    end
    get_roles
    @user = User.new
  end

  def create
    if current_user && !current_user.admin?
      # only admin can create new users directly
      redirect_to root_path and return
    end
    # if params[:user] && GDPR_COUNTRIES.include?(params[:user][:country])
    #   flash[:notice] = "This site does not support accounts from that country at this time."
    #   redirect_to root_path and return
    # end
    @user = User.new(users_params)
    @user.approved = true unless Setting.require_account_approval?
    @user.role = Role.reader unless @user.role_id.present? && current_user&.admin?
    if @user.save
      @user.deliver_verify_email!(current_user)
      if current_user&.admin?
        flash[:success] = "Account created"
        redirect_to users_path
      else
        flash[:success] = "Account registered. Expect an address confirmation email next."
        redirect_to root_path
      end
    else
      get_roles
      logger.debug "User create failed: #{ @user.errors.full_messages }"
      render :new
    end
  end

  def update
    @user = User.find(params[:id])

    users_params.delete(:password)
    if @user.update_attributes users_params
      redirect_to @user, notice: 'User was successfully updated.'
    else
      get_roles
      logger.debug "User update failed: #{ @user.errors.full_messages }"
      render action: "edit"
    end
  end

  def approve
    @user = User.find(params[:id])
    @user.approve!
    @user.deliver_activation_notice!
    redirect_to users_path(:needs_approval => true)
  end

  def destroy
    user = User.find_by_id(params[:id])
    if user && user.pwnd!(current_user)
      user.destroy
      flash[:notice] = "User deleted and assets reassigned to #{ current_user.name }"
    else
      flash[:error] = "User couldn't be deleted"
      flash[:error] += " - Unapprove user account first." if user.approved?
    end

    redirect_to users_url
  end

  private

  def get_roles
    @roles = Role.all.map{|r| [ I18n.translate(r.name), r.id]}
  end

  def users_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role_id, :speaker_id, :city, :state, :country,
                                 :active, :approved, :role_id, :photo, :remove_photo, :time_zone,
                                 :show_attendance, :show_contributor, :time_format)
  end
end
