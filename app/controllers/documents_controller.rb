class DocumentsController < ApplicationController

  include StickyNavigation

  before_action :check_nav_params, only: [:index]
  before_action :require_user
  before_action :require_admin,  only: [:generate]

  load_resource only: [:show, :edit, :update, :destroy, :download]
  authorize_resource

  def index
    @documents = Document.order("created_at DESC")
    @documents = @documents.where("status = ?", Document::COMPLETE) unless current_user.admin?
    @documents = @documents.page(param_context(:page)).per(param_context(:per))
    repaginate_if_needed(@documents)
  end

  # Saves the document with options for generation and queues it for processing
  def create
    @document = Document.new document_params
    @document.creator_id = current_user.id
    if @document.save
      DocumentWorker.perform_async(@document.id)
      flash[:notice] = "Document generation job queued for processing."
    else
      flash[:error] = "Your document generation request could not be saved: #{ @document.errors.full_messages.join(', ') }"
      get_organizer_selections
      logger.error "Document creation failed: #{ @document.errors.full_messages.join(', ') }"
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
    params.require(:document).permit(:format, :events, :presentations, :speakers, :publications)
  end
end
