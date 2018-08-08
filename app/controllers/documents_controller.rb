class DocumentsController < ApplicationController

  before_action :require_user
  before_action :require_admin,  only: [:generate]
  before_action :get_document,   only: [:show, :edit, :update, :destroy, :download]

  def index
    @documents = Document.all.order("created_at DESC").page(params[:page])
  end

  # Saves the document with options for generation and queues it for processing
  def create
    @document = Document.new document_params
    @document.creator_id = current_user.id
    if @document.save
      DocumentWorker.perform_async(@document.id)
      flash[:notice] = "Document generation job queued for processing."
    else
      flash[:error] = 'Your document generation request could not be saved.'
      get_organizer_selections
      logger.debug "Document creation failed: #{ @document.errors.full_messages }"
    end
    redirect_to documents_path
  end

  def download
    send_data @document.attachment.read, type: @document.content_type, disposition: 'inline', filename: @document.name
  end

  def destroy
    if can? :destroy, @document
      @document.destroy
      redirect_to documents_path
    else
      logger.debug "CanCan document delete permission denied for user #{ current_user.id } - #{ current_user.role_name }"
      flash[:notice] = "You do not have permission to delete documents."
      redirect_to root_url
    end
  end

  private

  def get_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:format, :conferences, :presentations, :speakers, :publications)
  end
end
