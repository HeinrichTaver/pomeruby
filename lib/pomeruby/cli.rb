# frozen_string_literal: true

require 'bubbletea'

module Pomeruby
  module CLI
    def self.run
      Bubbletea.run(Pomeruby::App.new, alt_screen: true)
    end
  end
end
