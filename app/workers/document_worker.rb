class DocumentWorker
  include Sidekiq::Worker

  sidekiq_options :retry => 1     # if it doesn't work, trying again is probably not going to help

  sidekiq_retries_exhausted do |msg, e|
    Rails.logger.error "Giving up generating Document: #{msg} - #{e}"
  end

  # This gets the temp CSV or PDF file moved over to the document and saved as the attachment.
  def assign_temp_file_to_document(temp_file, document)
    File.open(temp_file) do |f|
      document.attachment = f
    end
    File.delete(temp_file)
    document.save!
  end

  # Generate the PDF data, attach it to the document object, and make sure the status gets set to completed or failed.
  def handle_pdf(document)
    begin
      pdf = ConferenceDirectory.pdf(document.options)
      temp_file = Tempfile.new(['document', '.pdf'])
      pdf.render_file temp_file.path

      assign_temp_file_to_document(temp_file, document)

      document.complete!
    rescue => e
      logger.error "Document PDF generation for ID #{ document.id } failed with error #{ e }"
      document.failed!
    end
  end

  # Generate the CSV data, attach it to the document object, and make sure the status gets set to completed or failed.
  def handle_csv(document)
    begin
      temp_file = Tempfile.new(['document', '.csv'])

      class_name = document.options.map{|k,v| k.to_s if v}.compact.first # for CSV, there can be only one
      klass = class_name.classify.safe_constantize

      # To make this work, implement Class method #csv_header and instance method #csv_row on conference, presentation, and speaker.
      CSV.open(temp_file.path, "wb") do |csv|
        csv << klass.csv_header
        # find_each doesn't support sorting, but it's a CSV, so sort it yourself in the spreadsheet.
        klass.find_each do |item|
          csv << item.csv_row
        end
      end

      assign_temp_file_to_document(temp_file, document)
      document.complete!
    rescue => e
      logger.error "Document CSV generation for ID #{ document.id } failed with error #{ e }"
      document.failed!
    end
  end

  def perform(document_id)
    # The document entry gets created by the controller with the options for this particular job.
    begin
      document = Document.find document_id
    rescue => e
      logger.error "Document generation failed finding document with ID #{ document_id } with error #{ e }"
      return
    end

    case document.format
    when Document::PDF then
      handle_pdf(document)
    when Document::CSV then
      handle_csv(document)
    else
      logger.error "Document generation failed: unrecognized format '#{ document.format }'"
      document.failed!
    end
  end
end
