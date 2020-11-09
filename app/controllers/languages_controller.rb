class LanguagesController < ApplicationController

  include StickyNavigation

  before_action :check_nav_params, only: [:index]

  load_resource except: [:create, :new, :index]
  authorize_resource

  def index
    @languages = Language.order(params_to_sql('>languages.name'))
  end

  def show
    @language = Language.find params[:id]
  end

  def edit
  end

  def new
    @language = Language.new
  end

  def create
    @language = Language.new language_params
    @language.name&.strip!

    if @language.save
      redirect_to language_path(@language)
    else
      flash.now[:error] = "Your language could not be saved: #{ @language.errors.full_messages.join(", ") }"
      logger.error "Language save failed: #{ @language.errors.full_messages.join(", ") }"
      render 'new'
    end
  end

  def update
    if @language.update_attributes language_params
      redirect_to language_path(@language)
    else
      flash.now[:error] = "Your language could not be saved: #{ @language.errors.full_messages.join(', ') }"
      logger.error "Language update failed: #{ @language.errors.full_messages.join(', ') }"
      render 'edit'
    end
  end

  def destroy
    if can?(:destroy, @language) && @language.publications.empty?
      @language.destroy
    else
      flash[:notice] = "Language can't be deleted because publication(s) are using it."
    end

    redirect_to languages_path
  end

  private

  def get_language
    @language = Language.find params[:id]
  end

  def language_params
    params.require(:language).permit(:name, :abbreviation)
  end
end
