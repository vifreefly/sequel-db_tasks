# All possible rails db tasks https://jacopretorius.net/2014/02/all-rails-db-rake-tasks-and-what-they-do.html

namespace :db do
  task :preload do
    require 'uri'

    url = Sequel::DbTasks.configuration.database_url
    uri = URI.parse(url)
    raise "DB adapter is not postgres" if uri.scheme != "postgres"

    @conf = {
      url: url,
      db: uri.path.sub("/", ""),
      host: uri.host,
      port: uri.port,
      user: uri.user,
      password: uri.password
    }
  end

  # https://www.postgresql.org/docs/current/app-createdb.html
  desc "Create database"
  task create: :preload do
    env = { "PGPASSWORD" => @conf[:password] }
    if system env, "createdb", @conf[:db], "-h", @conf[:host], "-p", @conf[:port].to_s, "-U", @conf[:user]
      puts "Created database '#{@conf[:db]}'"
    end
  end

  # https://www.postgresql.org/docs/9.3/app-dropdb.html
  desc "Drop database"
  task drop: :preload do
    env = { "PGPASSWORD" => @conf[:password] }
    if system env, "dropdb", @conf[:db], "-h", @conf[:host], "-p", @conf[:port].to_s, "-U", @conf[:user]
      puts "Dropped database '#{@conf[:db]}'"
    end
  end

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
    Rake::Task["db:preload"].execute
    require 'sequel/core'
    require 'logger'

    Sequel.extension :migration
    version = args[:version].to_i if args[:version]

    Sequel.connect(@conf[:url], logger: Logger.new(STDOUT)) do |db|
      Sequel::Migrator.run(db, Sequel::DbTasks.configuration.migrations_path, target: version)
    end
  end

  # https://github.com/jeremyevans/sequel/blob/master/doc/migration.rdoc#dumping-the-current-schema-as-a-migration
  desc "Print current database schema"
  task :'schema:print' => :preload do
    exec "bundle", "exec", "sequel", "-d", @conf[:url]
  end
end
