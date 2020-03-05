# All possible rails db tasks https://jacopretorius.net/2014/02/all-rails-db-rake-tasks-and-what-they-do.html

namespace :db do
  task :preload, [:skip_adapter_validation] do |t, args|
    require 'uri'

    @url = Sequel::DbTasks.configuration.database_url
    uri = URI.parse(@url)

    unless args[:skip_adapter_validation]
      raise "DB adapter is not postgres" if uri.scheme != "postgres"
    end
  end

  ###

  # https://www.postgresql.org/docs/current/app-createdb.html
  desc "Create database"
  task create: :preload do
    env = { "DATABASE_URL" => @url }
    exec env, "postgressor", "createdb"
  end

  # https://www.postgresql.org/docs/current/app-dropdb.html
  desc "Drop database"
  task drop: :preload do
    env = { "DATABASE_URL" => @url }
    exec env, "postgressor", "dropdb"
  end

  ###

  # https://www.postgresql.org/docs/current/app-pgdump.html
  desc "Dump (backup) database"
  task dump: :preload do
    env = { "DATABASE_URL" => @url }
    exec env, "postgressor", "dumpdb"
  end

  # https://www.postgresql.org/docs/current/app-pgrestore.html
  desc "Restore database from backup"
  task :restore, [:restore_dump_file_path] do |t, args|
    raise "Restore dump file path is not provided" unless args.restore_dump_file_path
    Rake::Task["db:preload"].execute

    env = { "DATABASE_URL" => @url }
    command = ["postgressor", "restoredb", args.restore_dump_file_path]
    command << "--switch_to_superuser" if ENV["AS_SUPERUSER"] == "true"

    exec env, *command
  end

  ###

  # https://www.postgresql.org/docs/current/app-createuser.html
  desc "Create database user" # superuser is optional
  task create_user: :preload do
    env = { "DATABASE_URL" => @url }
    exec env, "postgressor", "createuser"
  end

  # https://www.postgresql.org/docs/current/app-dropuser.html
  desc "Drop database user"
  task drop_user: :preload do
    env = { "DATABASE_URL" => @url }
    exec env, "postgressor", "dropuser"
  end

  ###

  # https://github.com/jeremyevans/sequel/blob/master/doc/migration.rdoc#a-basic-migration
  desc "Generate migration file"
  task :gm, [:name] do |t, args|
    migrations_path = Sequel::DbTasks.configuration.migrations_path
    mkdir_p migrations_path

    time = Time.now.utc.strftime("%Y%m%d%H%M%S")
    filename = File.join(migrations_path, "#{time}_#{args.name}.rb")
    File.write(filename,
      <<~RUBY
        # #{filename}

        Sequel.migration do
          change do

          end
        end
      RUBY
    )

    puts "Created migration '#{filename}'"
  end

  # https://github.com/jeremyevans/sequel/blob/master/doc/migration.rdoc#running-migrations-from-a-rake-task
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    Rake::Task["db:preload"].execute(skip_adapter_validation: true)
    require 'sequel/core'
    require 'logger'

    Sequel.extension :migration
    version = args[:version].to_i if args[:version]

    Sequel.connect(@url, logger: Logger.new(STDOUT)) do |db|
      Sequel::Migrator.run(db, Sequel::DbTasks.configuration.migrations_path, target: version)
    end
  end

  # https://github.com/jeremyevans/sequel/blob/master/doc/migration.rdoc#dumping-the-current-schema-as-a-migration
  desc "Print current database schema"
  task :'schema:print' do
    Rake::Task["db:preload"].execute(skip_adapter_validation: true)
    exec "bundle", "exec", "sequel", "-d", @url
  end
end
