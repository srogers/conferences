module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I am on . . .
  #   When /^I visit . . .
  #
  # step definitions in web_steps.rb
  #
  def path_to(page_name)
    case page_name

      when /the home\s?page/, /the login page/
        '/'
      when /the new user page/
        new_user_path
      when /^the edit user "(.*?)" page$/i
        edit_user_path(User.where(:email => $1).first)

      # Add more mappings here.
      # Here is an example that pulls values out of the Regexp:
      #
      #   when /^(.*)'s profile page$/i
      #     user_profile_path(User.find_by_login($1))

      else
        begin
          page_name =~ /the (.*) page/
          path_components = $1.split(/\s+/)
          self.send(path_components.push('path').join('_').to_sym)
        rescue Object => e
          raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
                    "Now, go and add a mapping in #{__FILE__}"
        end
    end
  end
end

World(NavigationHelpers)
