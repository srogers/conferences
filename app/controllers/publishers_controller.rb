class PublishersController < ApplicationController

  include Sortability

  before_action :require_admin
  before_action :get_publisher, only: [:show, :edit, :update, :destroy]

  def index
    # doesn't participate in sticky_navigation
    @publishers = Publisher.order(params_to_sql('>publishers.name')).page(params[:page]).per(params[:per])
    existing = @publishers.map{|p| p.name}
    @incidentals = Publication.group(:publisher).count.select{|k,v| k.present? && !existing.include?(k)}.map{|k,v| OpenStruct.new(name:k, usages: v) }
  end

  # No UI for new or show
  # def show
  # end
  #
  # def new
  #   @publisher = Publisher.new
  # end

  def edit
  end

  def create
    @publisher = Publisher.new(publisher_params)
    @publisher.creator_id = current_user.id

    respond_to do |format|
      if @publisher.save
        format.html { redirect_to publishers_path, notice: 'Publisher was successfully created.' }
        format.json { render :show, status: :created, location: @publisher }
      else
        format.html { redirect_to publishers_path, errors: "Publisher couldn't be created: #{ @publisher.errors.full_messages.join(', ') }" }
        format.json { render json: @publisher.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @publisher.update(publisher_params)
        format.html { redirect_to publishers_path, notice: 'Publisher was successfully updated.' }
        format.json { render :show, status: :ok, location: @publisher }
      else
        format.html { render :edit }
        format.json { render json: @publisher.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @publisher.destroy
    respond_to do |format|
      format.html { redirect_to publishers_path, notice: 'Publisher was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def get_publisher
    @publisher = Publisher.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def publisher_params
    params.require(:publisher).permit(:name)
  end
end
