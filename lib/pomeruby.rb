# frozen_string_literal: true

require 'io/console'

require 'bubbles'
require 'bubbletea'
require 'lipgloss'

require_relative "pomeruby/config"
require_relative "pomeruby/database"
require_relative "pomeruby/helpers"

class Pomeruby
  include Helpers
  include Bubbletea::Model

  def initialize
    @db = Database.open(Config::POMERUBY_DB)

    @current_view = 'menu'

    @timer         = Bubbles::Timer.new(Config::POMO_BLOCK_IN_MINUTES)
    @timer_started = false
    @timer_paused  = false

    @task_blocks = ''

    _, @term_width = IO.console.winsize

    @menu_items = [
      { title: 'Timer', option: 'timer' },
      { title: 'Task List', option: 'tasks' },
    ].freeze

    @menu                 = Bubbles::List.new(@menu_items)
    @menu.fill_height     = false
    @menu.show_title      = false
    @menu.show_filter     = false
    @menu.show_pagination = false
    @menu.show_status_bar = false

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
      case message.to_s
      when 'q', 'ctrl+c'
        unless message.to_s == 'q' && @current_view == 'tasks' && @task_submitted == false
          return [self, Bubbletea.quit]
        end
      when 's'
        unless @timer_started
          @timer         = Bubbles::Timer.new(Config::POMO_BLOCK_IN_MINUTES)
          @timer_started = true

          return [self, @timer.init]
        end
      when ' ', 'space'
        if @timer_started
          @timer_paused = @timer.running?
          return [self, @timer.toggle]
        end
      when 'enter'
        if @current_view == 'tasks'
          if @task_input_focused < @task_inputs.length - 1
            @task_inputs[@task_input_focused].blur
            @task_input_focused += 1 if @task_input_focused + 1 < @task_inputs.length
            command = @task_inputs[@task_input_focused].focus

            return [self, command]
          else
            @task_submitted = true unless @task_inputs[0].value.empty?

            return [self, nil]
          end
        else
          @current_view = @menu.selected_item[:option]

          @menu, command = @menu.update(message)

          return [self, command]
        end
      when 'tab', 'down'
        if @current_view == 'tasks'
          @task_inputs[@task_input_focused].blur
          @task_input_focused += 1 if @task_input_focused + 1 < @task_inputs.length
          command = @task_inputs[@task_input_focused].focus

          return [self, command]
        end

        @menu, command = @menu.update(message)
        return [self, command]
      when 'shift+tab', 'up'
        if @current_view == 'tasks'
          @task_inputs[@task_input_focused].blur
          @task_input_focused -= 1 if @task_input_focused - 1 >= 0
          command = @task_inputs[@task_input_focused].focus

          return [self, command]
        end

        @menu, command = @menu.update(message)
        return [self, command]
      when 'esc'
        @current_view = 'menu' unless @timer.running?
      end
    when Bubbletea::WindowSizeMessage
      @term_width = message.width

      return [self, nil]
    when Bubbles::Timer::TickMessage, Bubbles::Timer::StartStopMessage
      return [self, nil] unless @timer_started

      @timer, command = @timer.update(message)
      return [self, command]
    when Bubbles::Timer::TimeoutMessage
      @timer_started = false
      @task_blocks += 'x'
      return [self, nil]
    else
      return [self, nil]
    end

    @task_inputs[@task_input_focused], command = @task_inputs[@task_input_focused].update(message)

    return if @current_view != 'menu'

    @menu, command = @menu.update(message)
    [self, command]
  end

  def view
    case @current_view
    when 'menu'
      view_menu
    when 'timer'
      view_timer
    when 'tasks'
      view_tasks
    else
      raise "view #{@current_view} doesn't exist"
    end
  end

  private

  def view_menu
    lines = []
    lines << place_centered(@term_width, 0, text_bold('Pomeruby'))
    lines << ''
    lines << ''
    lines << place_centered(@term_width, 0, @menu.view)
    lines << ''
    lines << ''
    lines << place_centered(@term_width, 0, text_italic('↑/↓ navigate | enter select | q quit'))
    lines.join("\n")
  end

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
        place_centered(@term_width, 0, text_italic('space toggle | q quit'))
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
    lines << place_centered(@term_width, 0, text_italic('esc menu | q quit'))
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
