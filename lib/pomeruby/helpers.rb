# frozen_string_literal: true

require 'lipgloss'

module Helpers
  @@text_bold = Lipgloss::Style.new.bold(true)
  @@text_italic = Lipgloss::Style.new.italic(true)

  module_function

  def text_bold(text)
    @@text_bold.render(text)
  end

  def text_italic(text)
    @@text_italic.render(text)
  end

  def place_centered(width, height, text)
    Lipgloss.place(width, height, :center, :center, text)
  end
end
