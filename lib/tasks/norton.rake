namespace :db do
  desc 'Performs a variety of integrity checks on the database. Useful for ensuring live data or test data makes sense, or for debugging.
        Requires access to information_schema DB. Runs on the DB of the specified environment. Supports VERBOSE and DEBUG output. REPAIR option will attempt to fix some issues.'

  task :norton => :environment do
    # This is particularly useful when loading fixtures with reference by name, because nothing checks to see that it actually exists.

    # add FLAG=anything to set one of the input flags
    @verbose   = ENV['verbose']   || ENV['VERBOSE']   # generates lots of output that might be of interest
    @debug     = ENV['debug']     || ENV['DEBUG']     # generates lots of output that probably isn't of interest unless you're modifying the script
    @recommend = ENV['recommend'] || ENV['RECOMMEND'] # triggers examination of some issues that can be fixed and prints SQL to perform repairs
    @repair    = ENV['repair']    || ENV['REPAIR']    # triggers examination of some issues that can be fixed and performs repairs

    raise "Don't use 'recommend' and 'repair' options together" if @recommend && @repair
    @verbose = true if @debug

    # Prints out the success or failure details of an attempt to update an object
    def report_repair_results(thing)
      if thing.errors.present?
        puts "repair failed:  #{ thing.errors.full_messages.join(', ') }"
      else
        puts "repaired OK."
      end
    end

    puts "Recommending repair SQL where possible" if @recommend
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
      next if ['sessions', 'schema_migrations', 'friendly_id_slugs'].include? reference['tablez']
      # In the query, "table_schema = 'public'" skips tables that are part of the PostgreSQL system infrastructure
      # skip columns that look like foreign keys but really aren't
      next if ['resource_id', 'session_id', 'klass_id'].include? reference['columnz']
      # figure out the table we're talking about - scorched_wombat_id => scorched_wombats
      referenced_table = reference['columnz'].split('_')[0..-2].join('_').tableize
      next if referenced_table.blank?

      # do some quick and dirty handling for foreign keys that reference users with an alternate name
      #referenced_table = 'users'   if ['created_by_id'].include? reference['columnz']
      referenced_table = 'users' if reference['columnz'] == 'creator_id'
      referenced_table = 'users' if reference['columnz'] == 'moderator_id'

      # skip these tables because they're too big and the data is probably OK
      #next if ['video_provider_id'].include?(reference['tablez'])
      #next if referenced_table == 'video_providers'  # references.video_provider_id is not a DB key, so there is no such table

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

      # Now consider the flip side of orphan records - the case where an expected child row doesn't exist. In some cases, the existence
      # of the child row is optional. In others we expect the child record to exist - this has to be specified manually.
      # Some tables we sort of expect a child, but we know they aren't always present. We just skip these entirely,
      # because getting a zillion warnings that something "might" be an error is unhelpful.
      #next if referenced_table == 'categories' and reference['tablez'] == 'votes'
      #next if referenced_table == 'concepts' and reference['tablez'] == 'comments'

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
          puts "#{ referenced_table } ID #{ parent['id']} has no records pointing to it in #{ reference['tablez'] }" + "#{ referenced_table == 'users' ? '.'+reference['columnz'] : '' }"
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
      if @repair
        puts "repairing . . ."
        # This is important, so when the roles re-load, they will get the same ID
        ActiveRecord::Base.connection.execute "TRUNCATE TABLE categories RESTART IDENTITY"
        Rake::Task["db:seed"].reenable
        Rake::Task["db:seed"].invoke
        puts "repaired - re-run rake db:norton to verify"
      else
        puts "delete all categories in the database, then run:  rake db:seeds"
      end
    else
      puts "roles look OK"
    end

    puts
    puts "done."
  end
end
