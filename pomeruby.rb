require 'bubbletea'
require 'lipgloss'

class Pomeruby
  include Bubbletea::Model

  def initialize
    @title_style =
      Lipgloss::Style.new
        .bold(true)
    @help_style =
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
      end
    else
      [self, nil]
    end
  end

  def view
    lines = []
    lines << Lipgloss.place(80, 0, :center, :center, @title_style.render('Pomeruby'))
    lines << ''
    lines << Lipgloss.place(80, 10, :center, :center, 'Hello, World!')
    lines << ''
    lines << Lipgloss.place(80, 0, :center, :center, @help_style.render('Press q to quit'))
    lines.join("\n")
  end
end

Bubbletea.run(Pomeruby.new, alt_screen: true)
