require 'bubbles'
require 'bubbletea'
require 'lipgloss'
require 'sqlite3'

XDG_DATA_HOME = ENV['XDG_DATA_HOME'] || File.expand_path('~/.local/share')

POMERUBY_DATA = "#{XDG_DATA_HOME}/pomeruby"
POMERUBY_DB   = "#{POMERUBY_DATA}/inventory.db"

class Pomeruby
  POMO_BLOCK_IN_MINUTES      = 60 * 25
  POMO_PAUSE_IN_MINUTES      = 60 * 5
  POMO_PAUSE_LONG_IN_MINUTES = 60 * 30

  include Bubbletea::Model

  def initialize
    @timer         = Bubbles::Timer.new(POMO_BLOCK_IN_MINUTES)
    @timer_started = false
    @timer_paused  = false

    @task_blocks = ""

    @term_width = `tput cols`.to_i

    @text_bold =
      Lipgloss::Style.new
        .bold(true)
    @text_italic =
      Lipgloss::Style.new
        .italic(true)

    @db = database_open

    @menu_items = [
      { title: "Timer", option: "timer"},
      { title: "Task List", option: "tasks"},
    ].freeze

    @menu                 = Bubbles::List.new(@menu_items)
    @menu.fill_height     = false
    @menu.show_title      = false
    @menu.show_filter     = false
    @menu.show_pagination = false
    @menu.show_status_bar = false
    @menu_selected        = nil
  end

  def init
    [self, Bubbletea.set_window_title('Pomeruby')]
  end

  def update(message)
    case message
    when Bubbletea::KeyMessage
      case message.to_s
      when 'q', 'ctrl+c'
        return [self, Bubbletea.quit]
      when 's'
        unless @timer_started
          @timer         = Bubbles::Timer.new(POMO_BLOCK_IN_MINUTES)
          @timer_started = true

          return [self, @timer.init]
        end
      when ' ', 'space'
        if @timer_started
          @timer_paused = @timer.running?
          return [self, @timer.toggle]
        end
      when 'enter'
        @menu_selected =  @menu.selected_item[:option]

        @menu, command = @menu.update(message)

        return [self, command]
      when 'esc'
        unless @timer.running?
          @menu_selected = nil
        end
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
      @task_blocks += "x"
      return [self, nil]
    else
      return [self, nil]
    end

    unless @menu_selected
      @menu, command = @menu.update(message)

      [self, command]
    end
  end

  def view
    return view_menu unless @menu_selected

    case @menu_selected
    when "timer"
      view_timer
    when "tasks"
      view_tasks
    else
      raise "view #{@menu_selected} doesn't exist"
    end
  end

  private

  def view_menu
    lines = []
    lines << place_centered(@term_width, 0, @text_bold.render('Pomeruby'))
    lines << ''
    lines << ''
    lines << place_centered(@term_width, 0, @menu.view)
    lines << ''
    lines << ''
    lines << place_centered(@term_width, 0, @text_italic.render('↑/↓ navigate | enter select | q quit'))
    lines.join("\n")
  end

  def view_timer
    timer =
      if @timer.timed_out?
        @text_bold.render("Block's up. Pause, now.")
      elsif @timer_started
        @timer.view
      else
        'Hello, World!'
      end

    lines = []
    lines << place_centered(@term_width, 0, @text_bold.render('Pomeruby'))
    lines <<
      unless @task_blocks.empty?
        place_centered(@term_width, 0, "Blocks completed: #{@task_blocks}")
      else
        ''
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
        place_centered(@term_width, 0, @text_italic.render('space toggle | esc menu | q quit'))
      elsif @timer_started
        place_centered(@term_width, 0, @text_italic.render('space toggle | q quit'))
      else
        place_centered(@term_width, 0, @text_italic.render('s start | esc menu | q quit'))
      end
    lines.join("\n")
  end

  def view_tasks
    lines = []
    lines << place_centered(@term_width, 0, @text_bold.render('Pomeruby'))
    lines << ''
    lines << ''
    lines << place_centered(@term_width, 0, 'Tasks, whither have ye gone?')
    lines << ''
    lines << ''
    lines << ''
    lines << place_centered(@term_width, 0, @text_italic.render('esc menu | q quit'))
    lines.join("\n")
  end

  def place_centered(width, height, text)
    Lipgloss.place(width, height, :center, :center, text)
  end

  def database_create
    SQLite3::Database.new("#{POMERUBY_DB}") do |db|
      db.foreign_keys = "ON"
      db.execute <<-SQL
        CREATE TABLE tasks
          ( id          INTEGER PRIMARY KEY
          , created_at  TEXT    DEFAULT CURRENT_TIMESTAMP NOT NULL
          , updated_at  TEXT    DEFAULT CURRENT_TIMESTAMP NOT NULL
          , description TEXT    UNIQUE                    NOT NULL
          , status      TEXT    DEFAULT 'open'            NOT NULL
                        CHECK(status IN ('open', 'in_progress', 'done'))
          , blocks_est  INTEGER
          , blocks_act  TEXT
          );
SQL

      db.execute <<-SQL
        CREATE TRIGGER update_tasks_updated_at
        AFTER UPDATE ON tasks
        BEGIN
           UPDATE tasks
              SET updated_at = CURRENT_TIMESTAMP
            WHERE id = OLD.id;
        END;
SQL
    end
  end

  def database_open
    Dir.mkdir(POMERUBY_DATA) unless Dir.exist?(POMERUBY_DATA)

    database_create unless File.exist?(POMERUBY_DB)

    SQLite3::Database.new("#{POMERUBY_DB}")
  end
end

Bubbletea.run(Pomeruby.new, alt_screen: true)
