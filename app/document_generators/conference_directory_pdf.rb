# Generates the overview document

class ConferenceDirectoryPdf < Prawn::Document

  include ApplicationHelper   # for date formatters
  include Rails.application.routes.url_helpers
  default_url_options[:host] = ENV['MAIL_HOST']

  SPEAKER_FIT = [50, 50]  # Width / Height limits for speaker images

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
    # Use #all because #find_each doesn't allow sorting.
    start_new_page
    table_data = [['<strong>Name</strong>', '<strong>Date</strong>', '<strong>Location</strong>']]
    Conference.all.order('start_date DESC').each do |conference|
      table_data << [
        "<link href='#{ conference_url(conference) }'>#{ conference.name }</link>",
        conference.date_span,
        conference.location
      ]
    end
    table table_data, :cell_style => { :inline_format => true, :border_width => 0 }
  end

  def presentations
    font_size 10
    # Use #all because #find_each doesn't allow sorting.  TODO - try to eager-load the tags
    start_new_page
    table_data = [['<strong>Name</strong>', '<strong>Speakers</strong>', '<strong>Conference</strong>', '<strong>Formats</strong>']]
    Presentation.includes(:publications, :speakers, :conference => :organizer).order('conferences.start_date DESC, presentations.name').each do |presentation|
      table_data << [
        "<link href='#{ presentation_url(presentation) }'>#{ presentation.name }</link>",
        presentation.speaker_names,
        presentation.conference_name,
        presentation.formats
      ]
    end
    table table_data, :cell_style => { :inline_format => true, :border_width => 0 }
  end

  def speakers
    font_size 10

    start_new_page
    Speaker.order(:name).each do |speaker|

      # Get the speaker image or default icon - development keeps these in the local filesystem, so the URL is a local file path.
      # In production, the url method returns a URL into S3.
      if Rails.env.development?
        image_url = "http://#{ENV['MAIL_HOST']}" + speaker.photo.url # the default icon returns a path - make it a URL
      else
        image_url = speaker.photo.url
      end

      opened_image = open image_url

      if opened_image.present?
        begin
          image_dimensions = FastImage.size image_url
          scaled_dimensions = get_scaled_dimensions image_dimensions
          image_height = scaled_dimensions[1]
          Rails.logger.debug "#{speaker.name} #{speaker.id} - image size: #{ image_dimensions } - scaled size: #{ scaled_dimensions }"
        rescue => e
          opened_image = nil
          image_height = 0
          Rails.logger.error "Error getting PDF image for speaker #{ speaker.name }: #{ e }"
        end
      else
        logger.debug "Opened image not present"
        image_height = 0
      end

      # If the speaker ever gets more info (like notes), add it to this array.
      details = [ActionView::Base.full_sanitizer.sanitize(speaker.description)]  # TODO - get styled text here

      top = cursor
      speaker_name_text = "<strong>#{ speaker.name }</strong>" # build the string with format here so we measure and output the same text height
      begin
        # Get the height of the description text
        box = Prawn::Text::Box.new details.join("\n\n"), { at: [70, top], width: 450, inline_format: true, document: self }
        box.render(dry_run: true)
        text_height = box.height

        # Get the height of the name - since we never let it wrap, this is really just the line height
        box = Prawn::Text::Box.new speaker_name_text, { at: [0, top], width: 450, inline_format: true, document: self }
        box.render(dry_run: true)
        name_height = box.height

        Rails.logger.debug "#{speaker.name} #{speaker.id} name height: #{ name_height }, description height: #{ text_height }"
      rescue Prawn::Errors::IncompatibleStringEncoding => e
        Rails.logger.error  "Error measuring text for speaker #{ speaker.name }: #{ e }"
        name_height = 10
        text_height = 10
      end

      # Here we have to detect the case where the text box will run past the end of the page and cause an automatic
      # pagination, because then the name or image will be stranded on one page, and the text box would get bumped to the next.
      # We have to force a new page, and then set the image and box both at the new cursor position at the top.
      displacement = [image_height, text_height].max
      if top - name_height - displacement < 10
        Rails.logger.debug "top + name - displacement: #{ top - name_height - displacement } - starting new page"
        start_new_page
        top = cursor
      else
        Rails.logger.debug "top + name - displacement: #{ top - name_height - displacement } - continuing on same page"
      end

      # Now actually place the speaker name, image, and description text box.
      text speaker_name_text, :inline_format => true
      move_down 3
      top = cursor    # this value is used as the top of the text box, so it comes out lined up with the top of the image

      begin
        image opened_image, :fit => SPEAKER_FIT if opened_image  # This will fail with certain image types, like interlaced PNGs
      rescue => e
        Rails.logger.error "Error rendering PDF image for speaker #{ speaker.name } speaker ID #{ speaker.id }: #{ e }"
      end
      begin
        text_box details.join("\n\n"), at: [70, top], width: 450, inline_format: true
      rescue Prawn::Errors::IncompatibleStringEncoding => e
        Rails.logger.error  "Error rendering text for speaker #{ speaker.name } speaker ID #{ speaker.id }: #{ e }"
        text_box "unformattable text - remove any special characters", at: [70, top], width: 450, inline_format: true
      end

      # Move down below the maximum size of the image, if the text doesn't already run down more than that
      Rails.logger.debug "#{speaker.name} #{speaker.id} - top: #{ top }, cursor: #{ cursor }"
      move_down text_height - image_height if text_height > image_height
      move_down 8  # a little extra pretty space
      Rails.logger.debug "moving down #{ text_height - image_height }" if text_height > image_height

    end
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
    conferences   if options[:conferences]
    presentations if options[:presentations]
    speakers      if options[:speakers]
    numbering
  end
end
