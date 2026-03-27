# frozen_string_literal: true

require 'lipgloss'

module Helpers
  TEXT_BOLD   = Lipgloss::Style.new.bold(true)
  TEXT_FAINT  = Lipgloss::Style.new.faint(true)
  TEXT_ITALIC = Lipgloss::Style.new.italic(true)

  module_function

  def text_bold(text)
    TEXT_BOLD.render(text)
  end

  def text_faint(text)
    TEXT_FAINT.render(text)
  end

  def text_italic(text)
    TEXT_ITALIC.render(text)
  end

  def place_centered(width, height, text)
    Lipgloss.place(width, height, :center, :center, text)
  end

  def place_header(width)
    place_centered(width, 0, text_bold('Pomeruby'))
  end

  def place_content(width, text)
    place_centered(width, 0, text)
  end

  def place_footer(width, text)
    place_centered(width, 0, text_faint(text))
  end
end
