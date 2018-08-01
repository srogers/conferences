module ApplicationHelper

  # Defined in http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html
  DEFAULT_TIME_ZONE = "America/Chicago"

  def title(text)
    content_for(:title) { text }
    content_tag(:h3, text)
  end

  # Returns true when the selected tab name is active, which we wheedle out of the controller and action names.
  def current_tab?(name)
    current = case name
    when 'conferences'
      controller_name == 'conferences' || controller_name == 'conference_users'
    when 'speakers'
      controller_name == 'speakers'
    when 'presentations'
      controller_name == 'presentations'
    when 'organizers'
      controller_name == 'organizers'
    when 'users'
      controller_name == 'users' && action_name != 'supporters' && !(action_name == 'summary' && params[:id] == @current_user.id.to_s)
    when 'settings'
      controller_name == 'settings'
    when 'documents'
      controller_name == 'documents'
    when 'summary'
      controller_name == 'users' && action_name == 'summary' && params[:id] == @current_user.id.to_s
    when 'profile'
      controller_name == 'accounts'
    when 'signup'
      controller_name == 'users' && ['new'].include?(action_name)
    when 'login'
      controller_name == 'user_sessions'
    else
      false
    end
    return current ? ' active' : ''
  end

  # This renders the FaceBook like/share buttons with descriptive text (e.g., "be the first of your friends to like this!
  # The button won't work without the associated meta tags, and the helper brings both of those things together in one shot.
  # The FB analytics initialization is built into the application template and happens on every page - that's a separate system.
  def fb_social_bar(options={})
    return unless @conference.present? || @presentation.present?
    og_url         = options[:url]          || request.base_url + request.path
    og_type        = options[:type]         || "article"
    og_title       = options[:title]
    og_description = options[:description]
    og_image_url   = options[:image_url]    || asset_url("logo.jpg")

    content_for :meta do
      render partial: 'shared/fb_og_meta_tags', locals: { og_url: og_url, og_type: og_type, og_title: og_title, og_description: og_description, og_image_url: og_image_url }
    end

    social_share_buttons = social_share_button_tag("Objectivist Conferences")
    fb_share = content_tag(:div, nil, :class => "fb-like", "data-share" => "true",  "data-width" => "450", "data-show-faces" => "true")
    # If the social links are placed on a page without a conference or presentation (such as the landing page) then the social sharing debug
    # and copy link buttons don't really make sense.
    if @conference.present?
      copy_link_button = link_to(icon('far', 'copy', "Copy Link"), '#', :class => "btn btn-primary btn-xs copy_link_to_clipboard")
      admin_dashboard_button =  current_user.try(:admin?) && Rails.env.production? ? link_to(icon('facebook', "Sharing Debug"), "https://developers.facebook.com/tools/debug/sharing/?q=#{ conference_url(@conference) }", class: "btn btn-xs btn-default", target: "_blank") : ''
    elsif @presentation.present?
      copy_link_button = link_to(icon('far', 'copy', "Copy Link"), '#', :class => "btn btn-primary btn-xs copy_link_to_clipboard")
      admin_dashboard_button =  current_user.try(:admin?) && Rails.env.production? ? link_to(icon('facebook', "Sharing Debug"), "https://developers.facebook.com/tools/debug/sharing/?q=#{ presentation_url(@presentation) }", class: "btn btn-xs btn-default", target: "_blank") : ''
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

  # create a submit button with a uniform look - we use a link to get around variations in browser styling of submit
  def my_submit_button(form, text=nil, html_options={})
    #, html_options  TODO - verify that a distinct DOM ID no longer needs to be forced on the save-and-continue button
    form.button :submit, text, {:class => 'btn btn-primary btn-sm'}.merge(html_options)
  end

  # this does the same thing as the two helpers above, with a separator in between - works with FormBuilder and SimpleForm
  def save_or_cancel(form, path, save_text=false, cancel_text=false)
    content_tag(:div, :class => 'form-actions btn-group') do
      # concatenate these, cuz it's a helper
      cancel_button(path, cancel_text) + (form.class == SimpleForm::FormBuilder ? my_submit_button(form, save_text) : form.button(save_text))
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

  # shows the location and includes the long or short country name when it's not "US" - takes a User or Conference
  def location_with_non_us_country(thing, format=:short)
    thing.location(thing.country == 'US' ? false : format)
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
      when :short       then "%m#{sep}%d#{sep}%y" # output date like  10/28/08
      when :long        then "%m#{sep}%d#{sep}%Y" # output date like  10/28/2008
      when :db          then "%Y#{sep}%m#{sep}%d" # output date like  2008-10-28
      when :yearless    then "%b %d"              # output date like  Oct 28
      when :url         then "%m#{sep}%d#{sep}%Y" # output date like  10_28_2008
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
end
