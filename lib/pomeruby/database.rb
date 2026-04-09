# frozen_string_literal: true

require 'sqlite3'

module Pomeruby
  module Database
    def self.create(database)
      SQLite3::Database.new(database) do |db|
        db.foreign_keys = 'ON'
        db.execute <<-SQL
        CREATE TABLE tasks
          ( id          INTEGER PRIMARY KEY
          , created_at  TEXT    DEFAULT CURRENT_TIMESTAMP NOT NULL
          , updated_at  TEXT    DEFAULT CURRENT_TIMESTAMP NOT NULL
          , description TEXT    UNIQUE                    NOT NULL
          , status      TEXT    DEFAULT 'open'            NOT NULL
                        CHECK(status IN ('open', 'in_progress', 'done', 'canceled'))
          , blocks_est  INTEGER
          , blocks_act  TEXT
          , deadline    TEXT
          );
        SQL

        db.execute <<-SQL
        CREATE TRIGGER update_tasks_updated_at
        AFTER UPDATE ON tasks
        BEGIN
           UPDATE tasks
              SET updated_at = CURRENT_TIMESTAMP
            WHERE id = OLD.id;
        END;
        SQL
      end
    end

    def self.open(database)
      Dir.mkdir(File.dirname(database)) unless Dir.exist?(File.dirname(database))

      create(database) unless File.exist?(database)

      SQLite3::Database.new(database)
    end

    def self.task_update(database, data)
      SQLite3::Database.new(database) do |db|
        db.foreign_keys = 'ON'
        db.execute <<-SQL
        UPDATE tasks
           SET description = '#{data[:task]}'
             , blocks_est  = '#{data[:estimation]}'
             , deadline    = '#{data[:deadline]}'
         WHERE tasks.id = #{data[:id]};
        SQL
      end
    end

    def self.task_insert(database, data)
      row_id = 0

      if data[:id].zero?
        SQLite3::Database.new(database) do |db|
          db.foreign_keys = 'ON'
          db.execute <<-SQL
          INSERT OR IGNORE INTO tasks (description, blocks_est, deadline)
          VALUES ('#{data[:task]}', '#{data[:estimation]}', '#{data[:deadline]}');
          SQL

          row_id = db.last_insert_row_id
        end
      else
        task_update(database, data)

        row_id = data[:id]
      end

      row_id
    end

    def self.task_listing(database)
      tasks = []

      SQLite3::Database.new(database) do |db|
        db.foreign_keys = 'ON'
        db.execute('SELECT description FROM tasks') do |row|
          tasks << row
        end
      end

      tasks
    end
  end
end
