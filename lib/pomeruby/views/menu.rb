# frozen_string_literal: true

require 'bubbles'

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
      menu                 = Bubbles::List.new(ITEMS)
      menu.fill_height     = false
      menu.show_title      = false
      menu.show_filter     = false
      menu.show_pagination = false
      menu.show_status_bar = false

      menu
    end

    def view(width, content)
      lines = []

      lines << place_header(width)
      lines << ''
      lines << ''
      lines << place_content(width, content.view)
      lines << ''
      lines << ''
      lines << place_footer(width, '↑/↓ navigate | enter select | q quit')

      lines.join("\n")
    end
  end
end
