module ApplicationHelper
  include StickyNavigation

  # Defined in http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html
  DEFAULT_TIME_ZONE = "America/Chicago"

  def title(text)
    # Strip out tags, so titles can use :strong, :i, etc. without garfing up the header title
    content_for(:title) { text.present? ? strip_tags(text) + ' -- ' : '' }
    content_tag(:h3, text)
  end

  # Returns true when the selected tab name is active, which we wheedle out of the controller and action names.
  def current_tab?(name)
    current = case name
    when 'events'
      controller_name == 'events' || controller_name == 'conference_users'
    when 'speakers'
      controller_name == 'speakers'
    when 'presentations'
      controller_name == 'presentations'
    when 'publications'
      controller_name == 'publications'
    when 'organizers'
      controller_name == 'organizers'
    when 'users'
      controller_name == 'users' && !['supporters', 'conferences'].include?(action_name) && !my_summary?
    when 'settings'
      controller_name == 'settings'
    when 'documents'
      controller_name == 'documents'
    # Account overlaps with other states, because "You" is highlighted when items in the drop-down are also highlighted
    when 'account'
      controller_name == 'accounts' || my_summary? || my_events? || my_watchlist?
    when 'profile'
      controller_name == 'accounts'
    when 'summary'
      my_summary?
    when 'my_events'
      my_events?
    when 'watchlist'
      my_watchlist?
    when 'about'
      ['about', 'supporters', 'contact'].include?(action_name)
    when 'signup'
      controller_name == 'users' && ['new'].include?(action_name)
    when 'login'
      controller_name == 'user_sessions'
    else
      false
    end
    return current ? ' active' : ''
  end

  # A UI helper that provides a user-facing name for the current event type
  def current_event_type
    param_context(:event_type).present? ? param_context(:event_type) : 'Event'
  end

  def my_events?
    controller_name == 'users' && action_name == 'events'
  end

  def my_watchlist?
    controller_name == 'user_presentations' && action_name == 'index'
  end

  # a helper for current_tab? - this requires a param qualifier because admin can look at the same info under the users tab
  def my_summary?
    controller_name == 'users' && action_name == 'summary' && params[:id] == @current_user.id.to_s
  end

  # pass in an expression without a sort direction. The sort param will be built off the current state, cycling through
  # ASC, DESC, and no sort. Set defaults in the controller, not here.
  def params_with_sort(expression)
    if params[:sort].present?
      if params[:sort].from(1) == expression
        # Reverse the direction of the existing sort, or remove it
        if ['+'].include? params[:sort][0]
          sort_string =  '-' + expression
        elsif ['<', '>'].include? params[:sort][0]
          sort_string =  '#' + expression  # this will be sent in the header click and neutralize the default
        else # '-'
          sort_string =  nil
        end
      else
        # We're changing to the default sort on a new column
        sort_string =  '+' + expression
      end
    else
      # Go from no sort to the default sort on the column
      sort_string =  '+' + expression
    end
    { sort: sort_string, page: 1 }
  end

  # Use this in the column header to build a clickable sorter that shows the current sort direction
  def sorting_header(text, path_helper, expression, icon='sort-alpha')
    new_sort = params_with_sort(expression)
    if params[:sort].present? && params[:sort].from(1) == expression  # Then the current sort is about this column
      logger.debug "params[:sort] = #{ params[:sort]}"
      sort_indicator = ['-', '<'].include?(params[:sort][0]) ? icon('fas', icon + '-up', :class => 'fa-fw') : icon('fas', icon + '-down', :class => 'fa-fw')
    else
      sort_indicator = ''
    end
    content_tag :span, class: 'sort-indicator-wrapper' do
      (link_to(text, method(path_helper).call(new_sort)) + sort_indicator).html_safe
    end
  end

  # This renders the FaceBook like/share buttons with descriptive text (e.g., "be the first of your friends to like this!
  # The button won't work without the associated meta tags, and the helper brings both of those things together in one shot.
  # The FB analytics initialization is built into the application template and happens on every page - that's a separate system.
  def fb_social_bar(options={})
    @sharable_object = @conference || @presentation || @publication || @speaker || false

    og_url         = options[:url]          || og_url_for(@sharable_object)
    og_type        = options[:type]         || "article"
    og_title       = options[:title]        || og_title_for(@sharable_object)
    og_description = options[:description]  || @sharable_object.description

    image = image_attributes
    og_image_url    = options[:image_url]    || image.url
    og_image_type   = options[:image_type]   || image.type
    og_image_width  = options[:image_width]  || image.width
    og_image_height = options[:image_height] || image.height

    content_for :meta do
      render partial: 'shared/fb_og_meta_tags', locals: {
        og_url: og_url,
        og_type: og_type,
        og_title: og_title,
        og_description: ActionController::Base.helpers.strip_tags(og_description),
        og_image_url: og_image_url, og_image_type: og_image_type, og_image_width: og_image_width, og_image_height: og_image_height,
      }
    end

    if Setting.facebook_sharing?
      fb_share = content_tag(:div, nil, :class => "fb-like", "data-share" => "true",  "data-width" => "450", "data-show-faces" => "true")
    else
      fb_share = ''.html_safe
    end
    social_share_buttons = social_share_button_tag("Objectivist Conferences")
    # If the social links are placed on a page without a conference or presentation (such as the landing page) then the social sharing debug
    # and copy link buttons don't really make sense.
    if @sharable_object.present?
      copy_link_button = link_to(icon('far', 'copy', class: 'fa-md fa-fw'), '#', :class => "mr-3 btn btn-primary btn-sm copy_link_to_clipboard", title: 'Copy page URL')
      admin_dashboard_button =  if current_user.try(:admin?) && Rails.env.production?
        link_to(icon('fab', 'facebook-square', "Sharing Debug"), "https://developers.facebook.com/tools/debug/sharing/?q=#{ url_by_class(@sharable_object) }", class: "btn btn-sm btn-default", target: "_blank")
      elsif current_user.try(:admin?)
        link_to(icon('fab', 'facebook-square', "Sharing Debug"), "#", class: "btn btn-sm btn-default disabled", title: 'only available in staging and production')
      else
        ''
      end
    else
      copy_link_button = ''
      admin_dashboard_button = ''
    end

    # Wrap the FaceBook like/share buttons and the social_sharing gem buttons in one DIV of fixed height, so the page
    # content won't bounce down when FB responds with the share/like button content.
    content_tag :div, id: "social-sharing-container" do
      social_share_buttons +
      fb_share +
      copy_link_button +
      admin_dashboard_button
    end
  end

  def alert_icon_for flash_type
    case flash_type
      when 'success'
        'fa fa-check-circle'
      when 'notice'
        'fa fa-check-circle'
      when 'error'
        'fa fa-times-circle'
      when 'alert'
        'fa fa-times-circle'
      when 'warn'
        'fa fa-warning'
      else
        ''
    end
  end

  def cancel_button(path, text='Cancel')
    button_text = text || 'Cancel'
    link_to button_text, path, :class => 'btn btn-secondary btn-sm'
  end

  # Provides a per-page selector that retains the current params context. The default per page is set in param_context.
  def per_page_selector
    selector = form_tag url_for(action: :index), method: :get do
      content = label_tag 'per page', nil, for: 'per', class: 'small'
      content << "&nbsp;".html_safe
      content << select_tag(:per, options_for_select( [2,3,4,5,6,7,8,9,10,11,12,13,14,15,20,25,30,50], selected: param_context(:per)), onchange: 'this.form.submit()')
      content << hidden_field_tag(:page, 1)
      content
    end
    selector.html_safe
  end

  # Pass in the controller name for the index path to be searched - it can't always be deduced from the view.
  def index_search_form
    # figure out where to send the search based on the page we're looking at right now
    index_path = send("#{controller_name}_path")
    search_form = form_for :search, html: { class: 'form-inline', :autocomplete => "off" }, url: index_path, method: :get do |f|
      content = "".html_safe
      if param_context(:tag).present?
        content << tagify(param_context(:tag), class: 'slim')
        content << logical_selector
      else
        param_context(:operator) # look at the value, so it gets saved, to persist changes introduced by the "All" button
      end
      content << text_field_tag(:search_term, param_context(:search_term), placeholder: "Search")
      content << hidden_field_tag(:page, 1, id: :reset_page)
      content << content_tag(:span, '', style: 'margin-right: 5px;')
      buttons = button_tag type: 'submit', class: 'btn btn-primary btn-sm' do
        icon('fas', 'search', class: 'fa-sm')
      end
      # Build the "All" button which clears the search and goes to page 1
      if param_context(:search_term).present? || param_context(:tag).present? || params[:heart].present?
        # For continuity, keep existing params and just eliminate :search_term, :tag, :heart, and :page
        index_path_with_params = send("#{controller_name}_path", search_term: '', tag: '', page: 1)
        buttons << link_to('All', index_path_with_params, class: "btn btn-sm btn-primary ml-2")
      end
      content << buttons
    end
    search_form.html_safe
  end

  # create a submit button with a uniform look - we use a link to get around variations in browser styling of submit
  def my_submit_button(form, text=nil, html_options={})
    #, html_options  TODO - verify that a distinct DOM ID no longer needs to be forced on the save-and-continue button
    form.button :submit, text, {:class => 'btn btn-primary btn-sm'}.merge(html_options)
  end

  # this does the same thing as the two helpers above, with a separator in between - works with FormBuilder and SimpleForm
  def save_or_cancel(form, path, save_text=false, cancel_text=false)
    content_tag(:div, class: 'save-or-cancel-wrapper') do
      content_tag(:div, :class => 'form-actions btn-group save-or-cancel') do
        # concatenate these, cuz it's a helper
        cancel_button(path, cancel_text) + (form.class == SimpleForm::FormBuilder ? my_submit_button(form, save_text) : form.button(save_text))
      end
    end
  end

  # Generate the full error messages in a div with ul/li list to replace the old Rails 2 f.messages helper
  # Uses the same styles that the original Rails 2 error CSS expects.
  # The attribute parameter is tagged on (not in Rails 2) to allow display of errors on base or other attributes
  # which aren't associated with fields so don't show up with SimpleForm's way of handling field errors.
  # Pass in an attribute like :base or related objects like [:base, :agents]
  def error_messages_for(form_object, alternate_heading=false, fields=false)
    return unless form_object && form_object.errors.present?
    fields = [fields] if fields && !fields.is_a?(Array)
    heading = content_tag(:strong, alternate_heading || "This item couldn't be saved because:")
    if fields
      messages = content_tag(:ul, fields.map{|field| form_object.errors[field].map{|e| "<span class=\"red\">#{ field }:</span> #{ e }".html_safe}}.flatten.compact.map{|msg| content_tag(:li, msg) }.join("\n").html_safe)
    else
      messages = content_tag(:ul, form_object.errors.full_messages.collect{|msg| content_tag(:li, msg) }.join("\n").html_safe)
    end

    return content_tag(:div, heading + messages, :class => "error_explanation", :id => "error_explanation")
  end

  def articlize(word)
    %w(a e i o u).include?(word[0].downcase) ? "an #{word}" : "a #{word}"
  end

  # Shows a complete location for an Event or Presentation - country_format can be false, :short, or :full
  def location(thing, country_format=:short)
    return 'unspecified' unless thing.present? && thing.respond_to?(:venue) && (thing.venue.present? || thing.location.present?)
    return thing.venue if [Conference::VIRTUAL, Conference::MULTIPLE].include? thing.venue

    elements = []
    if thing.venue.blank?
      elements << ['unspecified venue']
    else
      if thing.venue_url.present?
        elements <<  [link_to(thing.venue, thing.venue_url, target: '_blank')]
      else
        elements << [thing.venue]
      end
    end
    if thing.location.present?
      elements << ['––', location_with_non_us_country(thing, country_format)]
    end
    elements.join(' ').html_safe
  end

  # shows the location and includes the long or short country name when it's not "US" - takes a User or Conference
  def location_with_non_us_country(thing, format=:short)
    thing.location(thing.country == 'US' ? false : format)
  end

  # This is the entry point for getting formatted dates - wraps crashy and ugly strftime with a
  # simple conversion that won't blow up the view.
  def pretty_date(value, options={})
    style          = options[:style]    # let #date_format set the defaults for these
    sep            = options[:sep]
    localize       = options.keys.include?(:localize) ? options[:localize] : true
    undefined_text = options[:undefined_text] || 'n/a'

    value = Time.parse(value) if value.is_a?(String) rescue true
    begin
      time_zone = current_user.try(:time_zone)
    rescue
      time_zone = nil
    end

    if defined?(current_user) && localize && time_zone.present?
      value.in_time_zone(time_zone).strftime(date_format(:style => style, :sep => sep)) rescue undefined_text
    else
      value.strftime(date_format(:style => style, :sep => sep)) rescue undefined_text
    end
  end

  def humanize_boolean(boolean_value)
    [false, nil, ""].include?(boolean_value) ? "No" : "Yes"
  end

  # Sanitizes rich text based on an extensive whitelist of attributes built into Loofah:
  # https://github.com/flavorjones/loofah/blob/master/lib/loofah/html5/safelist.rb
  # Tiny hints of documentation at:  https://github.com/rails/rails-html-sanitizer
  def safe_list_sanitizer
    Rails::Html::SafeListSanitizer.new
  end

  private

  # This is basically hardcoded info about the one logo image used for FB sharing
  def image_attributes
    # Currently, the only image used is the main logo
    OpenStruct.new width: 1200, height: 630, type: 'image/jpeg', url: asset_url("logo.jpg")
  end

  # Format the date according to a named style; accept an alternate date separator.
  # Intended to be used by #pretty_date rather than being called directly.
  def date_format(options={})
    style = options[:style] || :pretty

    # Set some default separators based on different input types, allowing override to be passed in
    if options[:sep].present?
      sep = options[:sep]
    else
      sep = '/'
      sep = '_' if style == :url
      sep = '-' if style == :db
      sep = ':' if [:timelike, :timelike24].include?(style)
    end

    case style
    when :pretty      then "%b %d, %Y"          # output date like  Oct 28, 2008
    when :pretty_full then "%B %d, %Y"          # output date like  October 28, 2008
    when :short       then "%m#{sep}%d#{sep}%y" # output date like  10/28/08
    when :long        then "%m#{sep}%d#{sep}%Y" # output date like  10/28/2008
    when :db          then "%Y#{sep}%m#{sep}%d" # output date like  2008-10-28
    when :yearless    then "%B %d"              # output date like  October 28
    when :url         then "%m#{sep}%d#{sep}%Y" # output date like  10_28_2008
    when :year_only   then "%Y"                 # output year like  2008
    when :month_only  then "%b %Y"              # output date like  Oct 2008
    when :month_name  then "%b"                 # output short month name only like Oct
    when :timelike    then "%l#{sep}%M %p"      # output time like  10:25 AM
    when :timelike24  then "%H#{sep}%M:%S"      # output time like  14:25:16
    when :full        then "%m#{sep}%d#{sep}%y %l:%M %p"     # like 02/07/13 05:53 PM
    when :full_plus   then "%m#{sep}%d#{sep}%y %l:%M:%S %p"  # like 02/07/13 05:53:09 PM
    when :datestamp   then "%m#{sep}%d#{sep}%y %H:%M:%S"     # like 02/07/13 17:53:09
    else "%b %d, %Y"                            # bogus styles get pretty
    end
  end

  def url_by_class(object)
    if object.is_a? Conference
      event_url(object)
    elsif object.is_a? Presentation
      presentation_url(object)
    elsif object.is_a? Publication
      # Not every publication type has a URL - in that case, just use the site page as the URL.
      # This determines the source of the FB share preview image, but the click-through always goes to the shared page.
      object.url || publication_url(object)
    elsif object.is_a? Speaker
      speaker_url(object)
    else
      false
    end
  end

  def og_url_for(sharable_object)
    if sharable_object.is_a? Conference
      event_url sharable_object
    elsif sharable_object.present?
      polymorphic_url @sharable_object
    else
      request.base_url + request.path
    end
  end

  def og_title_for(sharable_object)
    if sharable_object.is_a? Conference
      sharable_object.name
    elsif sharable_object.is_a? Presentation
      sharable_object.name
    elsif sharable_object.is_a? Publication
      sharable_object.name
    else
      ''
    end
  end
end
