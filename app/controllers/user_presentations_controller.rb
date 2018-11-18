class UserPresentationsController < ApplicationController

  before_action :require_user, except: [:most_watched, :most_anticipated]  # guests shouldn't ever see any buttons that go here

  def index
    per_page = 10
    @user_presentations = current_user.user_presentations.includes(:presentation => :conference).order('conferences.start_date DESC', 'presentations.name')
    @user_presentations = @user_presentations.page(params[:page]).per(per_page)
  end

  def most_watched
    @presentations = Presentation.find_by_sql("
SELECT p.name as name, p.slug, count(up.presentation_id) as watchers
FROM presentations p, user_presentations up
WHERE p.id = up.presentation_id and up.completed_on is not null
GROUP BY p.name, p.slug, up.presentation_id
ORDER BY count(up.presentation_id) DESC
LIMIT 3
")
    render layout: false
  end

  def most_anticipated
    @presentations = Presentation.find_by_sql("
SELECT p.name as name, p.slug, count(up.presentation_id) as watchers
FROM presentations p, user_presentations up
WHERE p.id = up.presentation_id and up.notify_pubs
GROUP BY p.name, p.slug, up.presentation_id
ORDER BY count(up.presentation_id) DESC
LIMIT 3
")
    render layout: false
  end

  def notifications
    @notifications = Notification.includes(:user_presentation, :presentation_publication => :presentation).includes(:presentation_publication => :publication) \
                    .references(:user_presentation).where("user_presentations.user_id = ?", current_user&.id).order('notifications.created_at DESC').limit(3)

    render layout: false
  end

  def create
    @user_presentation = UserPresentation.new user_presentation_params.merge(user_id: current_user.id)
    @success = @user_presentation.save
    get_user_presentation_list
    respond_to do |format|
      format.html do
        if @success
          redirect_to presentation_path(@user_presentation.presentation.to_param)
        else
          flash[:error] = 'The presentation could not be added to your list.'
          logger.error "UserPresentation save failed: #{ @user_presentation.errors.full_messages }"
          if @user_presentation&.presentation_id
            redirect_to presentation_path(@user_presentation.presentation.to_param)
          else
            redirect_to presentations_path
          end
        end
      end
      # This renders /create.js.erb, which renders the _presentation partial for a specific entry in the presentations
      # listing, or the listing on conference show page.
      format.js
    end
  end

  def update
    get_user_presentation
    @user_presentation.update user_presentation_params
    get_user_presentation_list

    respond_to do |format|
      format.html do          # currently, only presentation/show uses this
        redirect_to presentation_path(@user_presentation.presentation.to_param)
      end
      format.js               # renders /update.js.erb which re-renders the presentation with the clicked object
    end
  end

  def destroy
    get_user_presentation
    if @user_presentation
      presentation_id = @user_presentation.presentation.to_param
      @user_presentation.destroy
      success = true
    else
      success = false
    end

    respond_to do |format|
      format.html do
        if success
          redirect_to presentation_path(presentation_id)
        else
          render body: nil
        end
      end
      format.js
    end
  end

  private

  def get_user_presentation
    @user_presentation = UserPresentation.find(params[:id])
  end

  def get_user_presentation_list
    @user_presentations = current_user.user_presentations
  end

  # :user_id is always overridden on create with the current_user's ID, and it can't be updated, so it's not allowed.
  def user_presentation_params
    params.require(:user_presentation).permit(:presentation_id, :notify_pubs, :completed_on)
  end
end
