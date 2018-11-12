require 'ostruct'
require "sequel/db_tasks/version"

module Sequel
  module DbTasks
    def self.configuration
      @configuration ||= OpenStruct.new(
        database_url: ENV["DATABASE_URL"],
        migrations_path: "db/migrate"
      )
    end

    def self.configure
      yield(configuration)
    end

    def self.load!
      Rake.application.add_import "#{__dir__}/db_tasks/tasks.rake"
    end
  end
end
