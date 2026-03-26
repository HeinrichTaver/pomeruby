# frozen_string_literal: true

require_relative "../helpers"

module Views
  module Menu
    extend Helpers

    module_function

    def view(width, menu)
      lines = []
      lines << place_centered(width, 0, text_bold('Pomeruby'))
      lines << ''
      lines << ''
      lines << place_centered(width, 0, menu.view)
      lines << ''
      lines << ''
      lines << place_centered(width, 0, text_italic('↑/↓ navigate | enter select | q quit'))
      lines.join("\n")
    end
  end
end
