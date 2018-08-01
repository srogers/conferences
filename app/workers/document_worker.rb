class DocumentWorker
  include Sidekiq::Worker

  sidekiq_options :retry => 1     # if it doesn't work, trying again is probably not going to help

  sidekiq_retries_exhausted do |msg, e|
    Rails.logger.error "Giving up generating Document: #{msg} - #{e}"
  end

  def handle_pdf(document, options)
    begin
      pdf = ConferenceDirectory.pdf(options)
      temp_file = Tempfile.new(['document', '.pdf'])
      pdf.render_file temp_file.path


      File.open(temp_file) do |f|
        document.attachment = f
      end
      File.delete(temp_file)

      document.save!
      document.complete!
    rescue => e
      logger.error "Document PDF generation for ID #{ document.id } failed with error #{ e }"
      document.failed!
    end
  end

  def handle_csv(document, options)
    # TODO - implement CSV
    document.failed!
    return
  end

  def perform(document_id)
    # The document entry gets created by the controller with the options for this particular job.
    begin
      document = Document.find document_id
    rescue => e
      logger.error "Document generation failed finding document with ID #{ document_id } with error #{ e }"
      return
    end

    # TODO - parse document options into a convenient hash
    options = { conferences: true }

    case document.format
    when Document::PDF then
      handle_pdf(document, options)
    when Document::CSV then
      handle_csv(document, options)
    else
      logger.error "Document generation failed: unrecognized format '#{ document.format }'"
      document.failed!
    end
  end
end
