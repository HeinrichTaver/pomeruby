# frozen_string_literal: true

require 'bubbles'

require_relative '../config'
require_relative '../helpers'

module Views
  module Timer
    extend Helpers

    module_function

    def init
      @@timer   = Bubbles::Timer.new(Config::POMO_BLOCK_IN_MINUTES)
      @@started = false
      @@paused  = false
      @@blocks  = ''

      [@@timer, @@started, @@paused]
    end

    def view(width, timer, started, paused)
      lines = []

      lines << place_header(width)
      lines <<
        if @@blocks.empty?
          ''
        else
          place_content(width, "Blocks completed: #{@@blocks}")
        end
      lines << ''
      lines <<
        if timer.timed_out?
          place_content(width, "Block's up. Pause, now.")
        elsif started
          place_content(width, timer.view)
        else
          place_content(width, 'Hello, World!')
        end
      lines <<
        if paused
          place_content(width, '(paused)')
        else
          place_content(width, '')
        end
      lines << ''
      lines << ''
      lines <<
        if paused
          place_footer(width, 'space toggle | esc menu | q quit')
        elsif started
          place_footer(width, 'space toggle')
        else
          place_footer(width, 's start | esc menu | q quit')
        end

      lines.join("\n")
    end

    def reset
      @@timer = Bubbles::Timer.new(Config::POMO_BLOCK_IN_MINUTES)

      @@timer
    end

    def mark_complete
      @@blocks += 'x'
    end
  end
end
