class PassagesController < ApplicationController

  before_action :require_admin
  before_action :set_passage, only: [:show, :edit, :update, :destroy]

  def index
    @passages = Passage.all.page(params[:page]).per(20)
  end

  def show
  end

  def new
    @passage = Passage.new
  end

  def edit
  end

  def create
    @passage = Passage.new(passage_params)
    @passage.creator_id = current_user.id

    respond_to do |format|
      if @passage.save
        format.html { redirect_to @passage, notice: 'Passage was successfully created.' }
        format.json { render :show, status: :created, location: @passage }
      else
        format.html { render :new }
        format.json { render json: @passage.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @passage.update(passage_params)
        format.html { redirect_to @passage, notice: 'Passage was successfully updated.' }
        format.json { render :show, status: :ok, location: @passage }
      else
        format.html { render :edit }
        format.json { render json: @passage.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @passage.destroy
    respond_to do |format|
      format.html { redirect_to passages_url, notice: 'Passage was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_passage
    @passage = Passage.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def passage_params
    params.require(:passage).permit(:name, :view, :assign_var, :content, :minor_version, :major_version, :update_type, :retain_versions )
  end
end
