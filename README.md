# Conferences

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
    rake db:schema:load
    rake db:seed

Set up your local .env file (not to be checked into git) and provide values for the following

    CONFERENCES_DATABASE_PASSWORD=''
    PORT='3000'

## Attachment Configuration

File storage is defined in config/initializers/carrierwave.rb

In development, attachments are stored as files, which resolves to /public/uploads

## Development Server

Start the development server with the standard `bundle exec rails s`. This won't start Sidekiq though. It can be started
in a separate window in the foreground (which is usually preferable) or the whole Procfile can be run from the same
process with `heroku local`.

### Background Workers

Background tasks are handled by Sidekiq.  Start the sidekiq process in development in the foreground
with `bundle exec sidekiq`.

## Special Gems and Configuration

### Rails ERD

This development-only gem maintains an entity-relationship DB diagram in the root directory. It gets updated automatically
with migrations. To generate it manually, run:

    bundle exec erd

### Bootstrap

Bootstrap is installed via the bootstrap gem.

### Sidekiq

Sidekiq is used for PDF generation. Sidekiq requires a queueing system - we're using Redis. Start in the foreground with:

    be sidekiq

Or run in the background by starting the server with `heroku local`.
The sidekiq web interface ( /sidekiq ) isn't hooked up yet . . .

### Redis

Redis comes from the Redis Cloud add on. The URL is automatically added to the config when the addon is provisioned.
The format for the Redis Cloud URL is:

    REDISCLOUD_URL: redis://rediscloud:[password]@[host]:[port]

The REDIS_PROVIDER is not automatically added, and it won't work without that. Manually add:

    heroku config:set REDIS_PROVIDER=REDISCLOUD_URL

When the Redis Cloud add-on is installed, the URL is automatically added to the environment with an arbitrary name and
password. The host and password are available in the Heroku resources tab, by double-clicking the Redis Cloud icon. Only
one database is allowed for Heroku apps, so the database name doesn't matter.

#### Restore Redis After Delete

On the free plan, the Redis DB will be destroyed after 30 days of inactivity. To create a new one, follow these steps:
 - On the landing or resources page, click on "Redis Cloud"
 - This will go to a Redis Labs page with an empty list of databases
 - Click the "+" and add
   * Name:  doesn't matter
   * You can copy the password from the original URL, or use the default - endpoint will be different anyway
   * Use the password and endpoint to update the connection string in app settings REDISCLOUD_URL
 - Restart the server

The Redis cloud URL is:  redis://rediscloud:[password]@[endpoint]

    redis://rediscloud:[password]@redis-12345.c47.us-east-1-2.ec2.cloud.redislabs.com:12345

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
 - Add a Procfile, and add config.ru
 - define development environment in .env (and git ignore that file)
 - list vendor assets in config/environments/production.rb for precompilation (if compiling assets at deployment)

### Config Vars

The Heroku config vars need to include values for the following:

    S3_BUCKET_NAME            (not in development)
    S3_KEY                    (not in development)
    S3_SECRET_KEY             (not in development)
    FB_APP_ID                 (use staging for develop - separate ID for production)
    GA_TRACKING_ID            (the Google Analytics tracking code - using staging for develop - staging: UA-90993426-2   production: UA-90993426-1 )
    MAIL_HOST                 (sets action_mailer.default_url_options - should NOT include http:// prefix. Used as the canonical domain name)

The app won't deploy (asset precompile will fail) if these are not defined, because the app won't boot. Set them with
the Heroku config command, like:

    heroku config:set S3_KEY=VALUE --remote staging

### Performance Monitoring

New Relic removed - no replacement chosen

### SSL (TLS) and Certificates

The site config and DNS hosting is migrated from the old appname.herokuapp.com format to the new name.com.herokudns.com format.
The details are explained [here](https://devcenter.heroku.com/articles/custom-domains).
Once paid dynos are turned on, [Automated Certificate Management](https://devcenter.heroku.com/articles/automated-certificate-management)
can be enabled, which easily and cheaply gets the site secure.

### Domain Name Managment

See the details [here](https://devcenter.heroku.com/articles/custom-domains). In brief steps:
1. Add the domain on Heroku

    `heroku domains:add www.objectivistmedia.com  --app conference-media`

    This will kick back something like:

    Configure your app's DNS provider to point to the DNS Target `environmental-macaw-ilnjyapxk1fapcmtn6y7g06x.herokudns.com.`

1. Configure the domain at DNS service provider using info from domain add command

Current domains on the app:

- objectivistmedia.com  <= Canonical domain name
- objectivistmedia.info
- objectivistmedia.net
- objectivistconferences.info

The MAIL_HOST environment variable is expected to contain the canonical domain name of the site. If the user arrives from
a different domain, the ApplicationController redirects to the MAIL_HOST domain wth a 301 to keep search robots happy. This
means that multiple domain names can be associated with the site, and the domain name can be changed by changing MAIL_HOST.

If the domain name changes, the domain for forced SSL must be updated in `config/environments/production.rb`

#### DNS and Nameserver Setup on Domain.com

Mapping from the Heroku instructions above to Domain.com - to setup a domain add DNS entries with the domain name,
followed by `herokudns.com` - at least one for the root, and optionally for www subdomain. For example:

|Type | Name | Content |
| --- | --- | --- |
|CNAME | www | www.objectivistconferences.info.herokudns.com |
|CNAME | @    |  objectivistconferences.info.herokudns.com |

Also, the "Domain Pointer" has to be changed in the "POINTER & SUBDOMAINS" section. Generally, it works to "stealth"
point it to the Heroku DNS name, like "URL Stealth" => "http://conference-media.herokuapp.com"

If the nameservers point to parked name servers, change them to `ns1.domain.com` and `ns2.domain.com`.

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

The easiest way to move data up and down from Heroku is using the
[pg-push/pg-pull](https://devcenter.heroku.com/articles/heroku-postgresql#pg-pull) commands.

    PGUSER=steve PGPASSWORD='' heroku pg:pull DATABASE_URL conferences_development --remote production

This command creates the named database, so rename the existing database before performing the download.
For this to work, the server and local Postgres versions must match. If they don't, you're pretty much hosed
unless you can change your local Postgres version to match what's running on Heroku.

#### Remote Database URL

It's possible to connect a PostgreSQL client directly the Heroku instance. The connection information is stored in the
database URLs which have a format like:

    HEROKU_POSTGRESQL_ONYX_URL: postgres://[username]:[password]@[host]:[port]/[database name]

#### Transferring Data Between Apps

To transfer production data back to staging for testing (ensure the staging database plan can handle it).

    heroku maintenance:on --remote staging
    heroku pg:copy conference-media::DATABASE_URL DATABASE_URL -a conference-media-staging
    # this will ask to confirm the copy by typing the name of the staging app - the DB that will be blasted
    heroku maintenance:off --remote staging

After that, staging is ready to go with the production data. Remember - this blasts the users also.

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

    git push origin develop              # push the develop branch to non-Heroku repo (normally github)
    git push origin <branchname>         # push <branchname> to non-Heroku repo, creating it if necessary (e.g. a shared feature branch)
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

### Secure Server Configuration
Production uses [Automated Certificate Management](https://devcenter.heroku.com/articles/automated-certificate-management#known-limitations)
and is forced into SSL mode in production config. Staging does not force SSL, because it runs on free dynos, and isn't
eligible for ACM. Domains have to be [configured](https://devcenter.heroku.com/articles/custom-domains) by pointing DNS to the herokudns URLs and not the old style herokuapp URLs.

## Managed Text

The Passages model holds versioned text to allow for semi-static pages that can be updated without re-deploying.
This was initially created to support the Privacy Policy (required for Facebook integration) but can be used anywhere.
Only the admin has access to Passages.

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
