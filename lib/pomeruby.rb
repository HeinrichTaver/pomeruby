# frozen_string_literal: true

require 'io/console'

require 'bubbletea'

require_relative 'pomeruby/cli'
require_relative 'pomeruby/config'
require_relative 'pomeruby/database'
require_relative 'pomeruby/views'

module Pomeruby
  class App
    include Bubbletea::Model

    def initialize
      _, @term_width = IO.console.winsize

      @current_view = :home
      @model_home = Pomeruby::Views::Home.init
      @model_tasks = Pomeruby::Views::Tasks.init
      @model_timer = Pomeruby::Views::Timer.init

      @db = Pomeruby::Database.open(Config::POMERUBY_DB)
    end

    def init
      [self, Bubbletea.set_window_title('Pomeruby')]
    end

    def update(message)
      case message
      when Bubbletea::WindowSizeMessage
        @term_width = message.width

        [self, nil]
      else
        case @current_view
        when :home
          new_model, command, next_view = Pomeruby::Views::Home.update(message, @model_home)
          @model_home = new_model
        when :tasks
          new_model, command, next_view = Pomeruby::Views::Tasks.update(message, @model_tasks)
          @model_tasks = new_model
        when :timer
          new_model, command, next_view = Pomeruby::Views::Timer.update(message, @model_timer)
          @model_timer = new_model
        end

        @current_view = next_view unless next_view.nil?
        [self, command]
      end
    end

    def view
      case @current_view
      when :home
        Pomeruby::Views::Home.view(@model_home, @term_width)
      when :tasks
        Pomeruby::Views::Tasks.view(@model_tasks, @term_width)
      when :timer
        Pomeruby::Views::Timer.view(@model_timer, @term_width)
      else
        raise "view #{@current_view} doesn't exist"
      end
    end
  end
end
