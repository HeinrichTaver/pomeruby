# frozen_string_literal: true

require 'bubbles'
require 'bubbletea'

require_relative '../config'
require_relative '../helpers'

module Pomeruby
  module Views
    module Timer
      extend Helpers

      class Model
        attr_accessor :timer, :started, :paused, :blocks

        def initialize
          @timer   = Bubbles::Timer.new(Config::POMO_BLOCK_IN_MINUTES)
          @started = false
          @paused  = false
          @blocks  = ''
        end
      end

      def self.init
        Model.new
      end

      def self.update(message, model)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when 'ctrl+c'
            [model, Bubbletea.quit, nil]
          when 'q'
            return [model, nil, nil] if model.timer.running?

            [model, Bubbletea.quit, nil]
          when 's'
            return [model, nil, nil] if model.started

            new_model = model.dup
            new_model.timer   = Bubbles::Timer.new(Config::POMO_BLOCK_IN_MINUTES)
            new_model.started = true

            [new_model, new_model.timer.init, nil]
          when ' ', 'space'
            return [model, nil, nil] unless model.started

            new_model = model.dup
            new_model.paused = model.timer.running?

            [new_model, new_model.timer.toggle, nil]
          when 'esc'
            next_view = :home unless model.timer.running?

            [model, nil, next_view]
          else
            new_model = model.dup
            new_model.timer, command = model.timer.update(message)

            [new_model, command, nil]
          end

        when Bubbles::Timer::TickMessage, Bubbles::Timer::StartStopMessage
          return [model, nil, nil] unless model.started

          new_model = model.dup
          new_model.timer, command = model.timer.update(message)

          [new_model, command, nil]

        when Bubbles::Timer::TimeoutMessage
          new_model = model.dup
          new_model.started = false
          new_model.blocks += 'x'

          [new_model, nil, nil]

        else
          [model, nil, nil]
        end
      end

      def self.view(model, width)
        lines = []

        lines << place_header(width)
        lines <<
          if model.blocks.empty?
            ''
          else
            place_content(width, "Blocks completed: #{model.blocks}")
          end
        lines << ''
        lines <<
          if model.timer.timed_out?
            place_content(width, "Block's up. Pause, now.")
          elsif model.started
            place_content(width, model.timer.view)
          else
            place_content(width, 'Hello, World!')
          end
        lines <<
          if model.paused
            place_content(width, '(paused)')
          else
            place_content(width, '')
          end
        lines << ''
        lines << ''
        lines <<
          if model.paused
            place_footer(width, 'space toggle | esc menu | q quit')
          elsif model.started
            place_footer(width, 'space toggle')
          else
            place_footer(width, 's start | esc menu | q quit')
          end

        lines.join("\n")
      end
    end
  end
end
