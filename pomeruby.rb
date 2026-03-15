require 'bubbles'
require 'bubbletea'
require 'lipgloss'

class Pomeruby
  include Bubbletea::Model

  def initialize
    @timer = Bubbles::Timer.new(60 * 25)

    @text_bold =
      Lipgloss::Style.new
        .bold(true)
    @text_italic =
      Lipgloss::Style.new
        .italic(true)
  end

  def init
    [self, lambda {
      Bubbletea.set_window_title('Pomeruby')
      @timer.init
     }]
  end

  def update(message)
    case message
    when Bubbletea::KeyMessage
      case message.to_s
      when 'q', 'ctrl+c'
        [self, Bubbletea.quit]
      end
    when Bubbles::Timer::TickMessage, Bubbles::Timer::StartStopMessage
      @timer, command = @timer.update(message)

      [self, command]
    else
      [self, nil]
    end
  end

  def view
    timer = if @timer.timed_out?
              @text_bold.render("Block's up. Pause, now.")
            else
              @timer.view
            end

    lines = []
    lines << Lipgloss.place(80, 0,
                            :center, :center,
                            @text_bold.render('Pomeruby'))
    lines << ''
    lines << Lipgloss.place(80, 10,
                            :center, :center,
                            timer)
    lines << ''
    lines << Lipgloss.place(80, 0,
                            :center, :center,
                            @text_italic.render('Press q to quit'))
    lines.join("\n")
  end
end

Bubbletea.run(Pomeruby.new, alt_screen: true)
