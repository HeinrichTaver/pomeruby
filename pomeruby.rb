require 'bubbles'
require 'bubbletea'
require 'lipgloss'

class Pomeruby
  POMO_BLOCK_IN_MINUTES      = 60 * 25
  POMO_PAUSE_IN_MINUTES      = 60 * 5
  POMO_PAUSE_LONG_IN_MINUTES = 60 * 30

  include Bubbletea::Model

  def initialize
    @timer         = Bubbles::Timer.new(POMO_BLOCK_IN_MINUTES)
    @timer_started = false
    @timer_paused  = false

    @text_bold =
      Lipgloss::Style.new
        .bold(true)
    @text_italic =
      Lipgloss::Style.new
        .italic(true)
  end

  def init
    [self, Bubbletea.set_window_title('Pomeruby')]
  end

  def update(message)
    case message
    when Bubbletea::KeyMessage
      case message.to_s
      when 'q', 'ctrl+c'
        [self, Bubbletea.quit]
      when 's'
        if !@timer.running? && !@timer_started
          @timer         = Bubbles::Timer.new(POMO_BLOCK_IN_MINUTES)
          @timer_started = true

          [self, @timer.init]
        end
      when ' ', 'space'
        if @timer_started && @timer.running?
          @timer_paused = true
        else
          @timer_paused = false
        end

        [self, @timer.toggle]
      end
    when Bubbles::Timer::TickMessage, Bubbles::Timer::StartStopMessage
      if @timer_started
        @timer, command = @timer.update(message)

        [self, command]
      else
        [self, nil]
      end
    else
      [self, nil]
    end
  end

  def view
    timer =
      if @timer.timed_out?
        @timer_started = false
        @text_bold.render("Block's up. Pause, now.")
      elsif @timer_started
        @timer.view
      else
        'Hello, World!'
      end

    lines = []
    lines << place_centered(80, 0, @text_bold.render('Pomeruby'))
    lines << ''
    lines << ''
    lines << place_centered(80, 0, timer)
    lines <<
      if @timer_paused
        place_centered(80, 0, '(paused)')
      else
        place_centered(80, 0, '')
      end
    lines << ''
    lines <<
      if @timer_started
        place_centered(80, 0, @text_italic.render('Press space to toggle'))
      else
        place_centered(80, 0, @text_italic.render('Press s to start'))
      end
    lines << place_centered(80, 0, @text_italic.render('Press q to quit'))
    lines.join("\n")
  end

  private
  def place_centered(width, height, text)
    Lipgloss.place(width, height, :center, :center, text)
  end
end

Bubbletea.run(Pomeruby.new, alt_screen: true)
