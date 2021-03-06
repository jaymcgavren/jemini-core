module Jemini
  class Game < Java::org::newdawn::slick::BasicGame
    include_class 'org.newdawn.slick.AppGameContainer'
    attr_accessor :screen_size, :fullscreen, :initial_state

    def initialize(options={})
      super(options[:screen_title] || 'Jemini Game')
      @initial_state = options[:initial_state] || :MainState
      @screen_size   = options[:screen_size] || Vector.new(800, 600)
      @fullscreen    = options[:fullscreen]
      @always_render = !!options[:always_render] # coercing to boolean, always_render can't be nil/null
      @fresh_state   = true
    end

    def init(container)
      @container = container
      @container.always_render = @always_render
      GameState.active_state = load_state(@initial_state)
      GameState.active_state.load
    end

    # depcrecated
    def screen_width
      screen_size.x
    end

    # depcrecated
    def screen_height
      screen_size.y
    end

    def app
      @app ||= create_app
    end

    def canvas
      @canvas ||= create_canvas
    end

    def update(container, delta)
      #don't tell the new state that it now has to update load time worth of a delta
      if @fresh_state
        delta = 0
        @fresh_state = false
      end
      # Workaround for image loading with Slick.
      # Must be done in game init or game loop (instead of immediately in the event).
      if @queued_state
#        @queued_state.load_resources
        game_state = load_state(*@queued_state)
        game_state.load(*@state_args)
        GameState.active_state = game_state
        @queued_state = nil
        @fresh_state = true
        return
      end
      GameState.active_state.manager(:input).poll(screen_size.x, screen_size.y, delta)
      GameState.active_state.manager(:message_queue).process_messages(delta)
      GameState.active_state.manager(:update).update(delta)
      GameState.active_state.manager(:game_object).__process_pending_game_objects
    end

    def render(container, graphics)
      GameState.active_state.manager(:render).render(graphics)
    end

    def load_state(state_name, args = [])
      require "states/#{state_name.underscore}" unless Object.const_defined? state_name.camelize
      @state_args = args
      state_name.camelize.constantize.new @container, self
    end

    def switch_state(state_name)
      queue_state load_state(state_name)
    end

    def queue_state(state, *args)
      @queued_state = [state, *args]
    end

    def fresh_state?
      @fresh_state
    end

    def active_state
      GameState.active_state
    end

  private
    def create_app
      @app = AppGameContainer.new(self, screen_size.x, screen_size.y, fullscreen)
      @app.vsync = true
      @app.maximum_logic_update_interval = 60
      @app.smooth_deltas = false #true
      #main.container = container
      @app.start
    end

    def create_canvas
      @canvas = Java::org::newdawn::slick::CanvasGameContainer.new(self)
      @canvas.set_size(screen_size.x, screen_size.y)
      container = @canvas.container
      container.vsync = false
#      container.vsync = true
      container.maximum_logic_update_interval = 60
      #container.start
      @canvas
    end

  end
end