# Conferences

# Development

## Initial Setup

To set up the dev environment:

    git clone git@github.com:srogers/conferences.git
    cd conferences

Ensure that rvm is set up, the ruby specified in Gemfile is installed, and probably a gem environment specified in the .rvmrc file.

Ensure that Bundler is installed on your machine

    gem install bundler

Run install script

    bundle install

    rake db:create
    rake db:migrate
    rake db:seed

Set up your local .env file (not to be checked into git) and provide values for the following

    CONFERENCES_DATABASE_PASSWORD=''
    PORT='3000'

## Attachment Configuration

File storage is defined in config/initializers/carrierwave.rb

In development, attachments are stored as files, which resolves to /public/uploads

## Foreman for Development Server

Foreman is a good local server to use with Heroku because it matches how Heroku looks at the Procfile and rackup files.
(see http://ddollar.github.com/foreman ). It's not necessary to 'bundle exec' foreman. Foreman runs the Procfile in
project root, which gets the environment from a .env file in the project root, typically containing the one
line: RACK_ENV=development  It can also specify the port, if desired. Obviously - don't check in the .env file.
To start foreman, run:

    foreman start  (optionally with -p<port-number>)

Foreman works with the new puma server. Foreman also runs the workers (named in Procfile). It's possible to start
Puma directly without the workers using a command like:

    PORT=8080 SSL_KEY_PATH=~/.ssl/server.key SSL_CERT_PATH=~/.ssl/server.crt bundle exec puma -C config/puma.rb -p 3001
    
Puma can sometimes be flakey, hanging up on certificate errors. In order to get around that, it's possible to run thin
instead, which is much more reliable (but doesn't handle ActionCable well). 

    thin start --ssl --ssl-key-file ~/.ssl/server.key --ssl-cert-file ~/.ssl/server.crt --port 3001

### Background Workers

Background tasks are handled by Sidekiq. 

## Special Gems and Configuration

### D3

D3 installation is handled by the d3-rails gem. D3 is otherwise ordinary, but is explicitly included in the application layout
in the HEAD tag because it has to be defined before the BODY, rather than in the footer with the rest of the asset stack.
The d3-rails gem packages the assets, but they don't build properly on Heroku so the assets are pulled in from the
Cloudflare CDN in the application layout (which supports SSL). Make sure the CDN D3 version matches the d3-rails version.

### Bootstrap

Bootstrap is installed via the bootstrap-sass gem.

### Sidekiq

Sidekiq is used for PDF generation. Sidekiq requires a queueing system - we're using Redis.

### Redis

Redis comes from the Redis Cloud add on. The URL is automatically added to the config when the addon is provisioned.
The format for the Redis Cloud URL is:

    REDISCLOUD_URL: redis://rediscloud:[password]@[host]:[port]

The REDIS_PROVIDER is not automatically added, and it won't work without that. Manually add:

    heroku config:set REDIS_PROVIDER=REDISCLOUD_URL
    
When the Redis Cloud add-on is installed, the URL is automatically added to the environment with an arbitrary name and
password. The host and password are available in the Heroku resources tab, by double-clicking the Redis Cloud icon. Only
one database is allowed for Heroku apps, so the database name doesn't matter.

## Tests

### Rspec

A fairly ordinary setup.

### Cucumber

TBD - only partially set up.

# Staging and Production

The project is configured as a Heroku app with data on Amazon S3. Part of this configuration is in the application,
and part is only visible from the Heroku command line.

## Heroku Configuration

Various little tweaks are required to make Heroku happy:

 - config.assets.initialize_on_precompile = false in config/application.rb, see https://devcenter.heroku.com/articles/rails3x-asset-pipeline-cedar#troubleshooting
 - Add 'thin' gem to the bundle, add a Procfile, and add config.ru
 - define development environment in .env (and git ignore that file)
 - list vendor assets in config/environments/production.rb for precompilation (if compiling assets at deployment)

### Config Vars

The Heroku config vars need to include values for the following:

    S3_BUCKET_NAME            (not in development)
    S3_KEY                    (not in development)
    S3_SECRET_KEY             (not in development)
    FB_APP_ID                 (use staging for develop - separate ID for production)
    GA_TRACKING_ID            (the Google Analytics tracking code - using staging for develop - staging: UA-90993426-2   production: UA-90993426-1 )
    MAIL_HOST                 (sets action_mailer.default_url_options - should NOT include http:// prefix)

The app won't deploy (asset precompile will fail) if these are not defined, because the app won't boot. Set them with
the Heroku config command, like:

    heroku config:set S3_KEY=VALUE --remote staging

### Performance Monitoring

New Relic whacked - monitoring TBD. 

### Heroku Database Configuration

When the new app gets its first push, a Postgres database will be allocated to it by default, so nothing is required to
set that up. But it is necessary to run

    heroku run rake db:seed --remote staging
    
to set up the database. The initial admin user must be created manually.

It's possible to connect a PostgreSQL client directly the Heroku instance. The connection information is stored in the
database URLs which have a format like:

  HEROKU_POSTGRESQL_ONYX_URL: postgres://[username]:[password]@[host]:[port]/[database name]

Heroku plans are documented here: https://devcenter.heroku.com/articles/heroku-postgres-plans
Some info about upgrading among tiers is here: https://devcenter.heroku.com/articles/upgrade-heroku-postgres-with-pgbackups

#### The pg_stat_statements Module

This extension is enabled by default on Heroku for all new Postgres 9.2 databases, created after 2014-February-11, and those
on the Hobby tier. You'll see it show up in schema.rb, and your local postgres may "fight" over schema.rb if you don't have
it enabled locally. Eventually a Heroku command will turn it on, but you turn it on manually in the Postgres
console by typing:

    CREATE EXTENSION pg_stat_statements

then run rake db:migrate again, and your schema.rb should be back in sync.

#### Database Backups

Backups are scheduled at 2 AM for both staging and production. The command is:

    heroku pg:backups:schedule DATABASE_URL --at '02:00 America/Chicago' --remote staging
    
Production was bootstrapped from a copy of the staging database 

#### Pushing and Restoring Data

It may be possible to populate the Heroku database directly from the local DB (not tested):

  https://devcenter.heroku.com/articles/heroku-postgresql#pg-push
  
For small databases, it is possible to pipe the data into the psql command, like:

      PGPASSWORD='' pg_dump  --no-acl --no-owner -h localhost -U srogers conferences_development | heroku pg:psql --remote staging

### Outgoing Email

Mail is configured to use Sendgrid. When the Add-On is provisioned, the username and password are added to the Heroku 
config vars automatically. ActionMailer configuration is here: https://devcenter.heroku.com/articles/sendgrid#ruby-rails

To access the dashboard:  heroku addons:open sendgrid  Or click on the SendGrid icon in Heroku Add-Ons list.

### Deployment

Deployment is handled with a rake task to ensure that the server gets migrated, and the version environment variable is
set, and the server is restarted. The master branch is deployed to demo and production, the develop branch is deployed
to staging. This is typical gitflow convention:  ( http://nvie.com/posts/a-successful-git-branching-model )

The footer shows the current application version based on the current git tag. In development this comes directly from
the local git repo. On Heroku, the repo is stripped away as part of deployment, so the version is stashed in the
environment variable APP_VERSION. The deployment task looks like:

    rake heroku:deploy REMOTE=staging

the default remote is staging. The task pushes the correct branch, migrates, sets the version, and restarts.

It is also possible to deploy manually with a direct git command. This is generally not a good idea, but it can be
helpful in special circumstances, such as deploying feature branches (which the rake task doesn't do)

    git push origin develop              # push the develop branch to Unfuddle
    git push origin <branchname>         # push <branchname> to Unfuddle, creating it if necessary (e.g. a shared feature branch)
    git push staging develop:master      # deploys the develop branch to staging master branch (Heroku always runs master)
    git push staging feature/test:master # deploys the test/feature branch to staging - feature branches can be deployed in-place
    git push production master

a particular tag can be pushed with a command like:

    git push staging v1.1.0^{}:master

##### Deploying Feature Branches

It's often desirable to push a feature branch so other people can test it or work on it before it's ready to be
merged into the development branch. The best way to do this is to treat the Unfuddle repo as the "home" repo for
trading branches - push and pull feature branches there among developers and push only the master branch to Heroku.

    git push origin feature/new_thing                              # push your feature to Unfuddle, creating a new branch
    git checkout -b feature/new_thing origin/feature/new_thing     # pull the remote feature branch using the same name

##### Assets

Currently, assets are configured to compile on Heroku during slug compilation, so no local precompile is required.

###### Vendor Assets

Currently there are no vendor assets.

## Facebook Integration

Facebook likes and shares are handled using the FB SDK. FB defines an App ID and secret for use with the JS SDK, which
allows for easy generation of Like and Share buttons. There is a separate Test App for staging, and a full app for 
production (with IDs specified in .env). Test Apps are described here:

    https://developers.facebook.com/docs/apps/test-apps
    
The quickstart guide for the JS SDK is here:    

    https://developers.facebook.com/quickstarts/735327976605607/?platform=web

The "dashboard" for the Facebook app is here:

    https://developers.facebook.com/apps/739379962867075/dashboard/  (staging)
    https://developers.facebook.com/apps/735327976605607/dashboard/

### Facebook Analytics

Facebook analytics is driven by a script in views/shared/_fb_analytics.html.erb
Events are defined in assets/javascripts/facebook_events.js

## Google Integration

### Google Analytics Configuration

There are two [GA accounts](https://analytics.google.com/analytics), one for staging and one for production. Analytics reporting is disabled in the development
and test Rails environments.

Website and Google Analytics configuration dianostics is available through [Tag Assistant Recordings](https://support.google.com/analytics/answer/6277302?hl=en&ref_topic=6277290).

### Google Search Configuration

Google search info is available form the [Webmasters Tools Dashboard](https://www.google.com/webmasters/tools/dashboard).

Documentation is [here](https://support.google.com/webmasters/answer/47334).

### Google Tag Manager

[Google Tag Manager](https://developers.google.com/tag-manager/) is configured on the Google site, but the Javascript is
not installed - not clear that it's worth it, because it's primarily aimed at providing marketeers a way around developers.
The [live preview mode](https://support.google.com/tagmanager/answer/6107056) might be worth it.

