# Sequel::DbTasks
Rake CLI tasks for Sequel ORM and Postgres. All available tasks:

```
rake db:create_user       # Create database user
rake db:drop_user         # Drop database user

rake db:create            # Create database
rake db:drop              # Drop database

rake db:gm[name]          # Generate migration file
rake db:migrate[version]  # Run migrations

rake db:schema:print      # Print current database schema
```

There is no `config/database.yml` file. Gem works with `DATABASE_URL` (https://github.com/jeremyevans/sequel/blob/master/doc/opening_databases.rdoc#using-the-sequelconnect-method), which is should match exactly this format:

```
postgres://user:password@localhost/database_name
```

By default gem takes db_url from DATABASE_URL env variable. You can set other value (see _Installation_ below).

## Installation
Gemfile:

```ruby
gem 'dotenv'
gem 'sequel-db_tasks', require: false
```

Run `bundle install`.

Rakefile:

```ruby
require 'sequel/db_tasks'
require 'dotenv/load' # require dotenv/load (dotenv gem) to get value of DATABASE_URL env variable inside .env file

Sequel::DbTasks.load!
```

You can tweak settings using configure block:

```ruby
# Rakefile

Sequel::DbTasks.configure do |config|
  config.database_url = ENV["DATABASE_URL"] # default value
  config.migrations_path = "db/migrate"     # default value
end

Sequel::DbTasks.load!
```

## Notes

* Inspired by https://github.com/sandelius/sequel-rake

* Capistrano task to migrate database while deployning:

```ruby
# lib/capistrano/tasks/sequel_migrate.rake

namespace :deploy do
  desc "Migrate sequel db"
  task :migrate do
    on roles(:all) do
      within release_path do
        execute :rake, 'db:migrate'
      end
    end
  end
end

after 'deploy:updated', 'deploy:migrate'
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
