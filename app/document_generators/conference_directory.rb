# Uses ConferenceDirectoryPdf to manage PDF generation and get it saved
require 'zip'
require 'open-uri'
require 'tempfile'

class ConferenceDirectory

  def self.pdf(options)
    ConferenceDirectoryPdf.new(options)
  end

  def self.zip(document_id)
    temp_filename = SecureRandom.hex(20)
    zip_file = Tempfile.open(temp_filename, "#{Rails.root}/tmp/")

    Zip::OutputStream.open(zip_file.path) do |zos|
      begin
        pdf = ConferenceDirectory.pdf(options)
        zos.put_next_entry("ConferenceDirectory.pdf")
        zos.print pdf.render
      rescue => e
        Rails.logger.error "Error building PDF zip #{ e }"
      end
    end

    zip_file.close
    return zip_file
  end
end
