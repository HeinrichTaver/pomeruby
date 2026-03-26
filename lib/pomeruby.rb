# frozen_string_literal: true

require 'io/console'

require 'bubbles'
require 'bubbletea'

require_relative "pomeruby/config"
require_relative "pomeruby/database"
require_relative "pomeruby/helpers"
require_relative "pomeruby/views"

class Pomeruby
  include Helpers
  include Bubbletea::Model

  def initialize
    @db = Database.open(Config::POMERUBY_DB)

    Views::Menu.init
    @current_view = 'menu'

    @timer         = Bubbles::Timer.new(Config::POMO_BLOCK_IN_MINUTES)
    @timer_started = false
    @timer_paused  = false

    @task_blocks = ''

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
    when Bubbletea::KeyMessage
      case @current_view
      when 'menu'
        command, view = Views::Menu.update(message)
        @current_view = view unless view.nil?
        [self, command]
      when 'timer' then update_timer_keys(message)
      when 'tasks' then update_tasks_keys(message)
      end

    when Bubbletea::WindowSizeMessage
      @term_width = message.width

      [self, nil]
    when Bubbles::Timer::TickMessage, Bubbles::Timer::StartStopMessage
      [self, nil] unless @timer_started

      @timer, command = @timer.update(message)
      [self, command]
    when Bubbles::Timer::TimeoutMessage
      @timer_started = false
      @task_blocks += 'x'
      [self, nil]
    else
      [self, nil]
    end
  end

  def update_timer_keys(message)
    case message.to_s
    when 'ctrl+c'
      [self, Bubbletea.quit]
    when 'q'
      [self, Bubbletea.quit] unless @timer.running?
    when 's'
      unless @timer_started
        @timer         = Bubbles::Timer.new(Config::POMO_BLOCK_IN_MINUTES)
        @timer_started = true
        [self, @timer.init]
      end
    when ' ', 'space'
      if @timer_started
        @timer_paused = @timer.running?
        [self, @timer.toggle]
      end
    when 'esc'
      @current_view = 'menu' unless @timer.running?
      [self, nil]
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
      @current_view = 'menu' unless @timer.running?
      [self, nil]
    else
      @task_inputs[@task_input_focused], command = @task_inputs[@task_input_focused].update(message)
      [self, command]
    end
  end

  def view
    case @current_view
    when 'menu'
      Views::Menu.view(@term_width)
    when 'timer'
      view_timer
    when 'tasks'
      view_tasks
    else
      raise "view #{@current_view} doesn't exist"
    end
  end

  private

  def view_timer
    timer =
      if @timer.timed_out?
        text_bold("Block's up. Pause, now.")
      elsif @timer_started
        @timer.view
      else
        'Hello, World!'
      end

    lines = []
    lines << place_centered(@term_width, 0, text_bold('Pomeruby'))
    lines <<
      if @task_blocks.empty?
        ''
      else
        place_centered(@term_width, 0, "Blocks completed: #{@task_blocks}")
      end
    lines << ''
    lines << place_centered(@term_width, 0, timer)
    lines <<
      if @timer_paused
        place_centered(@term_width, 0, '(paused)')
      else
        place_centered(@term_width, 0, '')
      end
    lines << ''
    lines << ''
    lines <<
      if @timer_paused
        place_centered(@term_width, 0, text_italic('space toggle | esc menu | q quit'))
      elsif @timer_started
        place_centered(@term_width, 0, text_italic('space toggle'))
      else
        place_centered(@term_width, 0, text_italic('s start | esc menu | q quit'))
      end
    lines.join("\n")
  end

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
