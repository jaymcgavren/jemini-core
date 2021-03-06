require 'managers/render_support/hardware_cursor'

class BasicRenderManager < Jemini::GameObject
  java_import 'org.newdawn.slick.geom.Circle'

  include HardwareCursor
  
  def load
    enable_listeners_for :before_render, :after_render
    @debug_queue = []
    use_available_hardware_cursor
  end

  def unload
    revert_hardware_cursor
  end
  
  #Render all game objects to the given graphics context.
  #Triggers :before_render, :after_render callbacks.
  def render(graphics)
    notify :before_render, graphics
    #game_state.manager(:game_object).game_objects.each { |game_object| game_object.draw if game_object.respond_to? :draw}
    game_state.manager(:game_object).layers_by_order.each do |game_objects|
      game_objects.each { |game_object| game_object.draw(graphics) if game_object.respond_to? :draw}
    end

    render_debug_overlay(graphics)
    notify :after_render, graphics
  end

  def debug(type, color, options)
    @debug_queue << {:type => type, :color => color}.merge(options)
  end

  def render_debug_overlay(graphics)
    pre_debug_color = graphics.color
    until @debug_queue.empty?
      debug_render = @debug_queue.shift
      color = debug_render[:color]
      color = Color.new(color) unless color.kind_of? Color
      graphics.color = color.native_color
      case debug_render[:type]
      when :point
        graphics.fill Circle.new(debug_render[:position].x, debug_render[:position].y, 2)
      end
    end
    graphics.color = pre_debug_color
  end
end