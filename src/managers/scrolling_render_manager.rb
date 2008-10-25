require 'managers/basic_render_manager'

class ScrollingRenderManager < BasicRenderManager
  attr_accessor :camera_position, :tracking_game_object
  alias_method :set_camera_position, :camera_position=
  
  def load(camera_position_or_tracking_game_object)
    if camera_position_or_tracking_game_object.kind_of? Vector
      @camera_position = camera_position_or_tracking_game_object
    else
      @tracking_game_object = camera_position_or_tracking_game_object
    end
    @gl = Java::org::newdawn::slick::opengl::renderer::Renderer.get
    super()
  end
  
  def renderer
    @gl
  end
  
  def render(graphics)
    translation = camera_position
    @gl.gl_translatef(translation.x, translation.y, 0.0)
    super
    @gl.gl_translatef(-translation.x, -translation.y, 0.0)
  end
  
  def camera_position
    @camera_position || calculate_object_position
  end
  
  def calculate_object_position
    #TODO: This should go once declared method overriding is possible.
    if @tracking_game_object.kind_of? TangibleSprite
      body_position = @tracking_game_object.body_position
      Vector.new(-(body_position.x - (640 / 2)), -(body_position.y - (480 / 2)))
    else
      Vector.new(-(body_position.x - (640 / 2)), -(body_position.y - (480 / 2)))
    end
  end
end