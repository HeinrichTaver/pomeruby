# frozen_string_literal: true

require 'bubbles'
require 'bubbletea'

require_relative '../helpers'

module Views
  module Home
    extend Helpers

    class Model
      attr_accessor :menu

      def initialize
        @menu = Bubbles::List.new(
          [
            { title: 'Timer',     view: :timer },
            { title: 'Task List', view: :tasks },
          ])

        @menu.fill_height     = false
        @menu.show_title      = false
        @menu.show_filter     = false
        @menu.show_pagination = false
        @menu.show_status_bar = false
      end
    end

    def self.init
      Model.new
    end

    def self.update(message, model)
      case message
      when Bubbletea::KeyMessage
        case message.to_s
        when 'q', 'ctrl+c'
          [model, Bubbletea.quit, nil]
        when 'enter'
          next_view = model.menu.selected_item[:view]

          new_model = model.dup
          new_model.menu, command = model.menu.update(message)

          [new_model, command, next_view]
        else
          new_model = model.dup
          new_model.menu, command = model.menu.update(message)

          [new_model, command, nil]
        end
      else
        [model, nil, nil]
      end
    end

    def self.view(model, width)
      lines = []

      lines << place_header(width)
      lines << ''
      lines << ''
      lines << place_content(width, model.menu.view)
      lines << ''
      lines << ''
      lines << place_footer(width, '↑/↓ navigate | enter select | q quit')

      lines.join("\n")
    end
  end
end
