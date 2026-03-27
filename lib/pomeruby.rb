# frozen_string_literal: true

require 'io/console'

require 'bubbles'
require 'bubbletea'

require_relative "pomeruby/config"
require_relative "pomeruby/database"
require_relative "pomeruby/helpers"
require_relative "pomeruby/views"

class Pomeruby
  include Bubbletea::Model

  include Helpers

  def initialize
    @db = Database.open(Config::POMERUBY_DB)

    @current_view = :home
    @model_home = Views::Home.init
    @model_timer = Views::Timer.init

    _, @term_width = IO.console.winsize

    @task_inputs = [
      create_input('Task', 'Task description'),
      create_input('Estimation', '(Optional) How many blocks will it take'),
    ]

    @task_input_focused = 0
    @task_submitted = false
  end

  def init
    [self, Bubbletea.set_window_title('Pomeruby')]
  end

  def update(message)
    case message
    when Bubbletea::WindowSizeMessage
      @term_width = message.width

      [self, nil]

    else
      case @current_view
      when :home
        new_model, command, next_view = Views::Home.update(message, @model_home)
        @model_home = new_model
        @current_view = next_view unless next_view.nil?
        [self, command]
      when :timer
        new_model, command, next_view = Views::Timer.update(message, @model_timer)
        @model_timer = new_model
        @current_view = next_view unless next_view.nil?
        [self, command]
      when :tasks then update_tasks_keys(message)
      end
    end
  end

  def update_tasks_keys(message)
    case message.to_s
    when 'ctrl+c'
      [self, Bubbletea.quit]
    when 'q'
      [self, Bubbletea.quit] if @task_submitted
    when 'enter'
      if @task_input_focused < @task_inputs.length - 1
        @task_inputs[@task_input_focused].blur
        @task_input_focused += 1 if @task_input_focused + 1 < @task_inputs.length

        command = @task_inputs[@task_input_focused].focus
        [self, command]
      else
        @task_submitted = true unless @task_inputs[0].value.empty?
        [self, nil]
      end
    when 'tab', 'down'
      @task_inputs[@task_input_focused].blur
      @task_input_focused += 1 if @task_input_focused + 1 < @task_inputs.length

      command = @task_inputs[@task_input_focused].focus
      [self, command]
    when 'shift+tab', 'up'
      @task_inputs[@task_input_focused].blur
      @task_input_focused -= 1 if @task_input_focused - 1 >= 0

      command = @task_inputs[@task_input_focused].focus
      [self, command]
    when 'esc'
      @current_view = :home unless @model_timer.timer.running?
      [self, nil]
    else
      @task_inputs[@task_input_focused], command = @task_inputs[@task_input_focused].update(message)
      [self, command]
    end
  end

  def view
    case @current_view
    when :home
      Views::Home.view(@model_home, @term_width)
    when :timer
      Views::Timer.view(@model_timer, @term_width)
    when :tasks
      view_tasks
    else
      raise "view #{@current_view} doesn't exist"
    end
  end

  private

  def view_tasks
    lines = []
    lines << place_centered(@term_width, 0, text_bold('Pomeruby'))
    lines << ''
    lines << place_centered(@term_width, 0, 'Tasks, whither have ye gone?')
    lines << ''

    @task_inputs.each_with_index do |input, i|
      label = ['Task:', 'Estimation:'][i]
      @task_inputs[@task_input_focused].focus if i == 0
      lines << "#{'%-11s' % label} #{input.view}"
    end

    lines <<
      if @task_submitted
        'Submitted'
      else
        ''
      end
    lines <<
      if @task_submitted
        place_centered(@term_width, 0, text_italic('esc menu | q quit'))
      else
        place_centered(@term_width, 0, text_italic('esc menu'))
      end
    lines.join("\n")
  end

  def create_input(name, placeholder)
    input = Bubbles::TextInput.new
    input.prompt = ""
    input.placeholder = placeholder

    input
  end
end

Bubbletea.run(Pomeruby.new, alt_screen: true)
