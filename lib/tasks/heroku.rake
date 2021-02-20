namespace :heroku do

  def run(*cmd)
    # This prevents the environment of the forked command from getting the wrong environment. Weirdly, when the
    # heroku:deploy task runs, it calls the copy of run() in the statements namespace - so both are fixed. The
    # culprit for getting the wrong Ruby into the environment seems to be the Heroku toolbelt.
    Bundler.with_unbundled_env { sh *cmd }
    raise "Command #{cmd.inspect} failed!" unless $?.success?
  end

  def confirm(message)
    print "\n#{message}\nAre you sure? [Yn] "
    raise 'Aborted' unless STDIN.gets.chomp.downcase == 'y'
  end

  def app_version
    %x[git describe master --tags --abbrev=0].strip
  end

  desc "Get a console"
  task(:console => :environment) do
    remote = ENV['remote'] || ENV['REMOTE'] || 'staging'   # the default environment

    confirm('Starting console on production') if remote == 'production'

    puts "starting console on #{ remote }"
    run "heroku run console --remote #{ remote }"
  end

  # This task uses the --remote flag rather than the --app flag and expects the git remotes to be named
  # "staging", and "production". The master branch is always pushed to production. The develop branch is
  # always pushed to staging.
  desc "Deploy to Heroku - defaults to develop => staging - use REMOTE=production for master => production"
  task(:deploy => :environment) do
    remote = ENV['remote'] || ENV['REMOTE'] || 'staging'   # the default environment

    abort('deploy environment has to be "staging" or "production"') unless ['staging', 'production'].include?(remote)

    puts "-----> Pushing to #{remote}..."
    if remote == 'production'
      confirm('Deploy to production')
      run "git push production master"
    elsif remote == 'staging'
      run "git push staging develop:master"
    end

    # This part does all the things that you might forget to do if you deployed manually.
    # That's the main reason to have a deployment task.
    puts "-----> Migrating..."
    run "heroku run rake db:migrate --remote #{remote}"

    puts "-----> Versioning..."
    run "heroku config:add APP_VERSION=#{app_version} --remote #{remote}"

    puts "-----> Restarting..."
    run "heroku restart --remote #{remote}"
  end
end
