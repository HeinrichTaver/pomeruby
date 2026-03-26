# frozen_string_literal: true

require 'bubbles'
require 'bubbletea'

require_relative '../helpers'

module Views
  module Menu
    extend Helpers

    ITEMS = [
      { title: 'Timer', option: 'timer' },
      { title: 'Task List', option: 'tasks' },
    ].freeze

    module_function

    def init
      @@menu                 = Bubbles::List.new(ITEMS)
      @@menu.fill_height     = false
      @@menu.show_title      = false
      @@menu.show_filter     = false
      @@menu.show_pagination = false
      @@menu.show_status_bar = false
    end

    def update(message)
      case message.to_s
      when 'q', 'ctrl+c'
        [Bubbletea.quit, nil]
      when 'enter'
        view = @@menu.selected_item[:option]
        @@menu, command = @@menu.update(message)
        [command, view]
      else
        @@menu, command = @@menu.update(message)
        [command, nil]
      end
    end

    def view(width)
      lines = []

      lines << place_header(width)
      lines << ''
      lines << ''
      lines << place_content(width, @@menu.view)
      lines << ''
      lines << ''
      lines << place_footer(width, '↑/↓ navigate | enter select | q quit')

      lines.join("\n")
    end
  end
end
