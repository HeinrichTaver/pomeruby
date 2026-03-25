# frozen_string_literal: true

module Config
  XDG_DATA_HOME = ENV['XDG_DATA_HOME'] || File.expand_path('~/.local/share')

  POMERUBY_DATA = "#{XDG_DATA_HOME}/pomeruby"
  POMERUBY_DB   = "#{POMERUBY_DATA}/inventory.db"

  POMO_BLOCK_IN_MINUTES      = 60 * 25
  POMO_PAUSE_IN_MINUTES      = 60 * 5
  POMO_PAUSE_LONG_IN_MINUTES = 60 * 30
end
