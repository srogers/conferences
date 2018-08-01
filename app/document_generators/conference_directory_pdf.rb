# Generates the overview document

class ConferenceDirectoryPdf < Prawn::Document

  include ApplicationHelper   # for date formatters
  include Rails.application.routes.url_helpers
  default_url_options[:host] = ENV['MAIL_HOST']

  SPEAKER_FIT = [70, 100]  # Width / Height limits for speaker images

  # This comes straight out of Prawn::Images::Image for how it gets the size of an image scaled to fit
  def get_scaled_dimensions(dimensions)
    width, height = dimensions
    bw, bh = SPEAKER_FIT
    bp = bw / bh.to_f
    ip = width / height.to_f
    if ip > bp
      w = bw
      h = bw / ip
    else
      h = bh
      w = bh * ip
    end
    return [w,h]
  end

  # Makes some changes to the tags in rich-text fields (presentation.description) so that the quirks
  # that make them look OK in HTML are transformed into quirks that make them look OK as PDF styled_text.
  def clean_rich_text(text)
    text.gsub('<p>','').gsub('</p>','').gsub('<blockquote>','<p style="margin-left: 10">').gsub('</blockquote>','</p>').gsub('<br><br>','<br>')
  end

  def cover_page
    move_down 100
    text "Objectivist Conferences", size: 42, style: :bold, align: :center
    text "Directory", size: 36, style: :bold, align: :center
    text "Generated #{ pretty_date Time.now }", size: 16, align: :center
  end

  def conferences
    font_size 10
    # Use #all because #find_each doesn't allow sorting.  TODO - try to eager-load the tags
    start_new_page
    text "conferences go here"
  end

  def numbering
    string = '<page>'
    options = { :at => [bounds.right - 150, 0],
                :width => 150,
                :align => :right,
                :page_filter => Proc.new {|p| p > 1},  # don't number the cover page
                :start_count_at => 1,
                :color => "000000" }
    number_pages string, options
  end

  def initialize(options)
    # super here is calling https://github.com/prawnpdf/prawn/blob/master/lib/prawn/document.rb initialize
    # Page Sizes: https://github.com/prawnpdf/prawn/blob/master/lib/prawn/document.rb  defined in PDF::Core::PageGeometry
    super :page_size => 'LETTER', info: { Title: 'Conference Directory', Author: 'Various', Creator: 'ObjectivistConferences.info', CreationDate: Time.now }

    # Generate the document according to the specified options

    cover_page
    conferences
    numbering
  end
end
