namespace :db do
  desc 'Performs a variety of integrity checks on the database. Useful for ensuring live data or test data makes sense, or for debugging.
        Requires access to information_schema DB. Runs on the DB of the specified environment. Supports VERBOSE and DEBUG output. REPAIR option will attempt to fix some issues.'

  task :norton => :environment do
    # This is particularly useful when loading fixtures with reference by name, because nothing checks to see that it actually exists.

    # add FLAG=anything to set one of the input flags
    @verbose   = ENV['verbose']   || ENV['VERBOSE']   # generates lots of output that might be of interest
    @debug     = ENV['debug']     || ENV['DEBUG']     # generates lots of output that probably isn't of interest unless you're modifying the script
    @repair    = ENV['repair']    || ENV['REPAIR']    # triggers examination of some issues that can be fixed and performs repairs

    @verbose = true if @debug

    # puts "Recommending repair SQL where possible" if @recommend          this is the default
    puts "Automatically executing repair SQL where possible" if @repair
    puts "Find Orphans..."

    db_name = ActiveRecord::Base.connection.current_database

    # First, find all the columns that seem to reference some other table because they have an attribute ending in '_id'
    # All the SQL databases have master look-up tables containing this info which are nearly the same, but not exactly.
    # For SQL Server
    #  sql = "SELECT TABLE_NAME as tablez, COLUMN_NAME as columnz FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_CATALOG ='#{ db_name }'
    #         AND COLUMN_NAME LIKE '%_id' ORDER BY TABLE_NAME"
    # For MySQL
    # sql = "SELECT TABLE_NAME as tablez, COLUMN_NAME as columnz FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = '#{ db_name }'
    #        AND COLUMN_NAME LIKE '%\_id' ORDER BY TABLE_NAME"
    # For PostgreSQL
    sql = "SELECT table_name as tablez, column_name as columnz
           FROM information_schema.columns
           WHERE table_catalog = '#{ db_name }' AND table_schema = 'public' AND column_name LIKE '%\_id' ORDER BY tablez"

    puts "Getting column name info from '#{ db_name }'"
    ActiveRecord::Base.establish_connection
    references = ActiveRecord::Base.connection.select_all(sql)
    puts "Got column name info . . ."

    # Now look at each something_id column and see if all the referenced somethings.id actually exist
    references.each do |reference|
      # Skip tables that we know we aren't concerned with
      next if ['sessions', 'schema_migrations', 'friendly_id_slugs', 'taggings'].include? reference['tablez']
      # In the query, "table_schema = 'public'" skips tables that are part of the PostgreSQL system infrastructure
      # skip columns that look like foreign keys but really aren't
      next if ['resource_id', 'session_id', 'klass_id'].include? reference['columnz']
      # figure out the table we're talking about - scorched_wombat_id => scorched_wombats
      referenced_table = reference['columnz'].split('_')[0..-2].join('_').tableize
      next if referenced_table.blank?

      # do some quick and dirty handling for foreign keys that reference users with an alternate name
      #referenced_table = 'users'   if ['created_by_id'].include? reference['columnz']
      referenced_table = 'users' if reference['columnz'] == 'creator_id'                # we skip most of these, but get it right, then skip them individually

      #next if ['attribute_id'].include?(reference['tablez'])   # for cases where a table should be skipped (e.g. due to size)
      #next if referenced_table == 'nonexistent'                # for cases where the _id suffix is coincidental and there is no corresponding table

      puts "Checking #{ reference['tablez'] } references to #{ referenced_table }" if @verbose
      orphans_sql = "SELECT * FROM \"#{ reference['tablez'] }\" WHERE \"#{reference['tablez']}\".#{reference['columnz']} NOT IN (SELECT id from \"#{referenced_table}\")"
      puts orphans_sql if @debug
      begin
        orphans = ActiveRecord::Base.connection.select_all(orphans_sql)
      rescue Exception => e
        puts "ERROR looking for orphans of table #{reference['tablez']} - it may not be a Rails table - skipping"
        puts e if @verbose
        next
      end
      orphans.each do |orphan|
        if @verbose
          puts "#{ reference['tablez'] }: #{ orphan.inspect } => #{reference['columnz']} #{ orphan[reference['columnz']] } does not exist in #{ referenced_table }"
        else
          puts "#{ reference['tablez'] } ID #{ orphan['id']} => #{reference['columnz']} #{ orphan[reference['columnz']] } does not exist in #{ referenced_table }"
        end
      end
      puts unless orphans.empty?

      # Now consider the flip side of orphan records - the case where an expected child row doesn't exist. In some cases,
      # the existence of the child row is optional. In others we expect the child record to exist - this has to be
      # specified manually. Some tables we sort of expect a child, but we know they aren't always present.
      # We just skip these entirely, because getting a zillion warnings that something "might" be an error is unhelpful.

      #next if referenced_table == 'things' and reference['tablez'] == 'thing_owners'  # this is the general form

      next if referenced_table == 'conferences' and reference['tablez'] == 'conference_users'              # a conference might have no attendees in users
      next if referenced_table == 'conferences' and reference['tablez'] == 'supplements'                   # a conference might have no supplemental info
      next if referenced_table == 'presentations' and reference['tablez'] == 'presentation_publications'   # presentations often have no publications
      next if referenced_table == 'presentations' and reference['tablez'] == 'publications'                # presentations often have no publications
      next if referenced_table == 'presentations' and reference['tablez'] == 'user_presentations'          # this is related to optional notifications, not speakers
      next if referenced_table == 'users' and reference['tablez'] == 'conference_users'                    # a user may have attended no conferences
      # next if referenced_table == 'organizers' and reference['tablez'] == 'conferences'                  # an organizer may have no conferences - but there won't be many, so let's see these

      # Notifications are user-created and optional, so most potential relationships pertaining to then will be missing
      next if referenced_table == 'presentation_publications' and reference['tablez'] == 'notifications'
      next if referenced_table == 'notifications' and reference['tablez'] == 'user_presentations'
      next if referenced_table == 'user_presentations' and reference['tablez'] == 'notifications'

      # Skip optional relationships with foreign keys - usually this is about creator_id
      next if referenced_table == 'users' and reference['tablez'] == 'conferences' and reference['columnz'] == 'creator_id'
      next if referenced_table == 'users' and reference['tablez'] == 'documents' and reference['columnz'] == 'creator_id'
      next if referenced_table == 'users' and reference['tablez'] == 'presentation_speakers' and reference['columnz'] == 'creator_id'
      next if referenced_table == 'users' and reference['tablez'] == 'presentations' and reference['columnz'] == 'creator_id'
      next if referenced_table == 'users' and reference['tablez'] == 'presentation_publications' and reference['columnz'] == 'creator_id'
      next if referenced_table == 'users' and reference['tablez'] == 'publications' and reference['columnz'] == 'creator_id'
      next if referenced_table == 'users' and reference['tablez'] == 'speakers' and reference['columnz'] == 'creator_id'
      next if referenced_table == 'users' and reference['tablez'] == 'supplements' and reference['columnz'] == 'creator_id'
      next if referenced_table == 'users' and reference['tablez'] == 'user_presentations' and reference['columnz'] == 'user_id'

      puts "Checking #{ referenced_table } children in #{ reference['tablez'] }" if @verbose
      parent_sql = "SELECT * FROM \"#{ referenced_table }\" WHERE \"#{referenced_table}\".id NOT IN (SELECT DISTINCT #{reference['columnz']} FROM \"#{reference['tablez']}\")"
      puts parent_sql if @debug
      begin
        lonely_parents = ActiveRecord::Base.connection.select_all(parent_sql)
      rescue Exception => e
        puts "ERROR looking for parents of table #{reference['tablez']} - it may not be a Rails table - skipping"
        puts e if @verbose
        next
      end
      lonely_parents.each do |parent|
        if @verbose
          puts "#{ referenced_table }: #{ parent.inspect } has no records pointing to it in #{ reference['tablez'] }"
        else
          puts "#{ referenced_table } ID #{ parent['id']} #{parent['name']} has no records pointing to it in #{ reference['tablez'] }" + "#{ referenced_table == 'users' ? '.'+reference['columnz'] : '' }"
        end
      end
    end

    puts
    puts "checking publication dates . . ."
    count = 0
    changed = 0
    Publication.find_each do |publication|
      next if publication.published_on.present?

      count += 1
      # First, flag it for manual fix if it's from YouTube - because we can get that info
      if publication.format ==  Publication::YOUTUBE
        puts
        puts "Fix publication ID #{ publication.id } '#{ publication.name }' manually - look up publication date on YouTube."
        next
      end

      # Next, try to deduce it from the conference
      if publication.presentations.present?
        dates = publication.presentations.map{|p| p&.conference&.start_date}.compact.uniq
        if dates.length == 1
          changed += 1
          if @repair
            publication.published_on = dates.first + 1.year
            publication.editors_notes = [publication.editors_notes, 'publication date estimated based on conference'].join("\n")
            publication.save
            puts "failed to save publication ID #{ publication.id }  '#{ publication.name }' - #{publication.errors.full_messages}" if publication.errors.present?
          else
            puts "recommendation: Publication ID #{publication.id } '#{ publication.name }' - assign publication date of: #{ dates.first + 1.year }"
          end
        elsif dates.length > 1
          # puts "#{ publication.presentations.length }  #{ publication.presentations.map{|p| p&.conference&.start_date}.compact.join(',') } "
          puts "manually fix publication ID #{ publication.id }  '#{ publication.name }' - pick among conference dates: #{dates.join(', ')}"
        else
          puts "manually fix publication ID #{ publication.id }  '#{ publication.name }' - can't deduce a date for it."
        end
      end
    end
    puts
    puts "looked at #{count} publications, #{@repair ? 'recommended' : 'performed'} #{changed} changes."

    puts
    puts "Checking Speakers for possible duplicates . . ."
    speakers = Speaker.all.to_ary  # This is probably OK, since speakers is relatively small
    speakers.each do |speaker|
      speakers.each do |candidate|
        next if candidate.id == speaker.id  # itself, not a duplicate
        # See if the first and last names are the same, ignoring middle names, middle initial, etc.
        speaker_name_parts = speaker.name.split(' ').map{|s| s.downcase }
        candidate_name_parts = candidate.name.split(' ').map{|s| s.downcase }
        if speaker_name_parts.first + speaker_name_parts.last == candidate_name_parts.first + candidate_name_parts.last
          puts "Speaker ID #{ speaker.id } '#{speaker.name}' looks suspiciously like ID #{ candidate.id } #{candidate.name}"
          # don't report this one again
          speakers.delete_at(speakers.index(candidate))
        end
      end
    end

    puts
    puts "Checking Users . . ."
    User.find_each do |user|
      puts "User ID #{user.id} #{user.email} (#{ user.role_names.join(', ') }):  #{ user.errors.full_messages }" unless user.errors.empty?
      # We don't "repair" these because approval is at the admin's discretion
      puts "User ID #{user.id} #{user.email}: is terminated but still has an active account." if user.active? && !user.approved?
    end

    puts
    puts "Checking Roles"
    category_names = Role.all.map{|c| c.name}.sort
    if category_names != Role::ROLES.sort
      puts "Database category names don't match up with Role::ROLES"
    else
      puts "roles look OK"
    end

    puts
    puts "done."
  end
end
