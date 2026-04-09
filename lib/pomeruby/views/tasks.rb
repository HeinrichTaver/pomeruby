# frozen_string_literal: true

require 'bubbles'
require 'bubbletea'

require_relative '../config'
require_relative '../database'
require_relative '../helpers'

module Pomeruby
  module Views
    module Tasks
      extend Pomeruby::Helpers

      FIELDS = [
        { label: 'Task'       , placeholder: 'Task description' },
        { label: 'Estimation' , placeholder: '(Optional} How many blocks will it take' },
        { label: 'Deadline'   , placeholder: '(Optional} Due date for this task' },
      ]

      class Model
        attr_accessor :inputs, :focused, :submitted

        def initialize
          @inputs = FIELDS.map do |input|
            create_input(input[:label], input[:placeholder])
          end
          @focused   = 0
          @submitted = 0
        end

        private

        def create_input(name, placeholder)
          input             = Bubbles::TextInput.new
          input.prompt      = ''
          input.placeholder = placeholder

          input
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
            return [model, Bubbletea.quit, nil] unless model.submitted.zero?

            new_model = model.dup
            new_model.inputs[model.focused], command = model.inputs[model.focused].update(message)

            [new_model, command, nil]
          when 'tab', 'down'
            new_model = model.dup
            new_model.inputs[model.focused].blur
            new_model.focused += 1 if model.focused + 1 < model.inputs.length

            command = new_model.inputs[new_model.focused].focus

            [new_model, command, nil]
          when 'shift+tab', 'up'
            new_model = model.dup
            new_model.inputs[model.focused].blur
            new_model.focused -= 1 if model.focused - 1 >= 0

            command = new_model.inputs[new_model.focused].focus

            [new_model, command, nil]
          when 'enter'
            new_model = model.dup

            if model.focused < model.inputs.length - 1
              new_model.inputs[model.focused].blur
              new_model.focused += 1 if model.focused + 1 < model.inputs.length

              command = new_model.inputs[new_model.focused].focus

              [new_model, command, nil]
            else
              new_model.submitted = Pomeruby::Database.task_insert(
                Config::POMERUBY_DB, {
                  id: model.submitted,
                  task: model.inputs[0].value,
                  estimation: model.inputs[1].value || nil,
                  deadline: model.inputs[2].value || nil
                })

              [new_model, nil, nil]
            end
          when 'esc'
            [model, nil, :home]
          else
            new_model = model.dup
            new_model.inputs[model.focused], command = model.inputs[model.focused].update(message)

            [new_model, command, nil]
          end
        else
          [model, nil, nil]
        end
      end

      def self.view(model, width)
        lines = []

        lines << place_header(width)
        lines << ''
        lines << place_content(width, 'Tasks, whither have ye gone?')
        lines << ''

        model.inputs.each_with_index do |input, idx|
          model.inputs[model.focused].focus if idx == 0
          lines << "#{'%-11s' % FIELDS[idx][:label]}: #{input.view}"
        end

        lines <<
          if model.submitted.nonzero?
            "Submitted as id #{model.submitted}"
          else
            ''
          end
        lines <<
          if model.submitted.nonzero?
            place_footer(width, 'esc menu | q quit')
          else
            place_footer(width, 'esc menu')
          end

        lines.join("\n")
      end
    end
  end
end
