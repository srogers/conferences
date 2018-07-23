class UsersController < ApplicationController

  before_action :require_admin, except: [:new, :create, :supporters, :summary]   # new, create, and supporters are open
  before_action :require_user,  only: [:summary]

  def index
    @require_account_approval = Setting.require_account_approval?
    if params[:needs_approval].present?
      @users = User.needing_approval.order(:created_at)
    else
      @users = User.all.order(:email)
    end
    @users = @users.includes(:role).page(params[:page]).per(20)
  end

  # Drives the Supporters page in the top-level menu - which is mostly run by the pages controller, but this item is not static.
  def supporters
    @editors = User.editors.where('show_contributor')
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
    @user = User.find(params[:id])
    raise CanCan::AccessDenied unless @user == current_user || current_user.admin?
    @conferences_attended = current_user.conferences.order('start_date DESC')
    @conferences_created = Conference.where(:creator_id => current_user.id).count
    @presentations_created = Presentation.where(:creator_id => current_user.id).count
    @speakers_created = Speaker.where(:creator_id => current_user.id).count
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
    @user = User.new(users_params)
    @user.role = Role.reader unless @user.role_id.present? && current_user && current_user.admin?
    if @user.save
      @user.deliver_verify_email!(current_user)
      if current_user && current_user.admin?
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
      flash[:error] = "User couldn't be deleted - make sure user is unapproved first."
      flash[:error] += " Deactivate user account first." if user.active?
    end

    redirect_to users_url
  end

  private

  def get_roles
    @roles = Role.all.map{|r| [ I18n.translate(r.name), r.id]}
  end

  def users_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role_id, :city, :state, :country,
                                 :active, :approved, :role_id, :photo, :remove_photo, :time_zone, :show_attendance)
  end
end
