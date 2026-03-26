# frozen_string_literal: true

require_relative "../helpers"

module Views
  module Menu
    extend Helpers

    module_function

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
