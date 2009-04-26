require 'behaviors/spatial'

class Physical < Gemini::Behavior
  # TODO: Move to Math?
  SQUARE_ROOT_OF_TWO = Math.sqrt(2)
  INFINITE_MASS = Java::net::phys2d::raw::Body::INFINITE_MASS
  
  include_class "net.phys2d.raw.Body"
  include_class "net.phys2d.raw.shapes.Box"
  include_class "net.phys2d.raw.shapes.Circle"
  include_class "net.phys2d.raw.shapes.Line"
  include_class "net.phys2d.raw.shapes.Polygon"
  include_class "net.phys2d.raw.shapes.ConvexPolygon"
  include_class "net.phys2d.math.Vector2f"
  
  attr_reader :mass, :name, :shape
  depends_on :Spatial
  depends_on :Updates
  #wrap_with_callbacks :move
  declared_methods :height, :width, :mass, :mass=, :set_mass, :shape, :body_position, :body_position=, :set_body_position,
                   :set_shape, :name, :name=, :rotation, :rotation=, :set_rotation, :add_force, :force,
                   :set_force, :come_to_rest, :add_to_world, :remove_from_world, :set_physical_debug_mode,
                   :physical_debug_mode=, :restitution, :restitution=, :set_restitution,
                   :add_velocity, :set_velocity, :velocity=,
                   :angular_velocity, :set_angular_velocity, :angular_velocity=,
                   :set_static_body, :rotatable=, :set_rotatable, :rotatable?, :velocity, :wish_move,
                   :set_movable, :movable=, :movable?, #:set_safe_move, :safe_move=,
                   :damping, :set_damping, :damping=, :set_speed_limit, :speed_limit=, #, :speed_limit
                   :angular_damping, :set_angular_damping, :angular_damping=,
                   :gravity_effected=, :set_gravity_effected, :friction, :set_friction, :friction=,
                   :get_collision_events, :box_size, :physics_bitmask, :physics_bitmask=, :set_physics_bitmask,
                   :add_excluded_physical, :rotate, :radius
  wrap_with_callbacks :mass=
  
  def load
    @mass = 1
    @shape = Box.new(1,1)
    setup_body
    @body.restitution = 0.0
    @body.user_data = @target
    @angular_damping = 0.0
    @target.enable_listeners_for :collided
    @target.on_after_move { move @target.x , @target.y}
    @target.on_update {|delta| set_angular_velocity(angular_velocity - (angular_velocity * (@angular_damping * (1.0/mass) ))) }
  end
  
  def add_excluded_physical(physical_game_object)
    @body.add_excluded_body physical_game_object.instance_variable_get(:@__behaviors)[:Physical].instance_variable_get(:@body)
  end
  
  def physics_bitmask
    @body.bitmask
  end
  
  def physics_bitmask=(bitmask)
    @body.bitmask = bitmask
  end
  alias_method :set_physics_bitmask, :physics_bitmask=
  
  
  def body_position
    @body.position
  end
  
  def body_position=(vector)
    # set_position doesn't take a vector, only x/y
    @body.set_position(vector.x, vector.y)
  end
  alias_method :set_body_position, :body_position=
  
  def x
    @body.position.x
  end
  
  def y
    @body.position.y
  end
  
  def set_position(x, y)
    @body.set_position(x, y)
  end
  
  def speed_limit=(vector_or_shared_value)
    if vector_or_shared_value.kind_of? Numeric
      axis_limit_x = axis_limit_y = vector_or_shared_value / SQUARE_ROOT_OF_TWO
    else
      axis_limit_x = vector_or_shared_value.x
      axis_limit_y = vector_or_shared_value.y
    end
    @body.set_max_velocity(axis_limit_x, axis_limit_y)
  end
  alias_method :set_speed_limit, :speed_limit=
  
#  def safe_move=(safe_move)
#    @safe_move = safe_move
#    if safe_move
#      puts "adding safe move listener"
#      listen_for(:collided, @target) do
#        puts "collision event"
#        if @safe_move
#          puts "position: #{@body.position}"
#          puts "last position: #{@body.last_position}"
#          #@body.set_position(@body.last_position.x, @body.last_position.y)
#          puts "reseting position to #{@last_x}, #{@last_y}"
#          @body.set_position(@last_x, @last_y)
#        end
#      end
#    end
#  end
#  alias_method :set_safe_move, :safe_move=
  
  def wish_move(x, y)
    # WARNING: @body.last_position is not to be trusted. We'll just handle it ourselves.
    @last_x = @target.x
    @last_y = @target.y
    @body.move(x, y)
    #@body.set_position(@last_x, @last_y) if @target.game_state.manager(:physics).colliding? @body
  end
  
  def move(x_or_vector, y=nil)
    if x_or_vector.kind_of? Numeric
      @body.move(x_or_vector, y)
    else
      @body.move(x_or_vector.x, x_or_vector.y)
    end
  end
  
  def width
    @body.shape.bounds.width
  end
  
  def height
    @body.shape.bounds.height
  end
  
  def radius
    @body.shape.radius
  end
  
  def box_size
    @body.shape.size
  end
  
  def rotation=(rotation)
    @body.rotation = Gemini::Math.degrees_to_radians(rotation)
  end
  alias_method :set_rotation, :rotation=
  
  def rotate(degrees)
    @body.adjust_rotation Gemini::Math.degrees_to_radians(degrees)
  end
  
  def rotation
    Gemini::Math.radians_to_degrees(@body.rotation)
  end
  
  def rotatable?
    @body.rotatable?
  end
  
  def rotatable=(rotatable)
    @body.rotatable = rotatable
  end
  alias_method :set_rotatable, :rotatable=
  
  def add_force(x_or_vector, y = nil)
    if y.nil?
      @body.add_force(x_or_vector.to_phys2d_vector)
    else
      @body.add_force(Vector2f.new(x_or_vector, y))
    end
  end
  
  def set_force(x, y)
    @body.set_force(x, y)
  end
  
  def force
    @body.force
  end
  
  def add_velocity(x_or_vector, y = nil)
    if x_or_vector.kind_of? Vector
      @body.adjust_velocity(x_or_vector.to_phys2d_vector)
    else
      @body.adjust_velocity(Java::net::phys2d::math::Vector2f.new(x_or_vector, y))
    end
  end
  
  def velocity
    @body.velocity.to_vector
  end
  
  def velocity=(vector)
    @body.adjust_velocity(Java::net::phys2d::math::Vector2f.new(vector.x - @body.velocity.x, vector.y - @body.velocity.y))
  end
  alias_method :set_velocity, :velocity=
  
  def angular_velocity
    @body.angular_velocity
  end
  
  def angular_velocity=(delta)
    @body.adjust_angular_velocity(delta - angular_velocity)
  end
  alias_method :set_angular_velocity, :angular_velocity=
  
  def come_to_rest
    current_velocity = @body.velocity
    add_velocity(-current_velocity.x, -current_velocity.y)
    set_angular_velocity(0)
    @body.is_resting = true
  end
  
  def mass=(mass)
    @mass = mass
    x, y = @target.x, @target.y
    @body.set(@shape, @mass)
    # TODO: Consider moving to set_shape
    # A body's position is lost when it moves, reset the position to where it was
    @body.move x, y
  end
  alias_method :set_mass, :mass=
  
  def restitution
    @body.restitution
  end
  
  def restitution=(restitution)
    @body.restitution = restitution
  end
  alias_method :set_restitution, :restitution=
  
  def set_shape(shape, *params)
    # Save off data that is destroyed when @body.set is called
    saved_damping = damping
    saved_angular_damping = angular_damping
    saved_body_position = body_position
    saved_position = @target.position
    saved_x, saved_y = @target.x, @target.y
    if shape.respond_to?(:to_str) || shape.kind_of?(Symbol)
      params = [params.map {|vector| vector.to_phys2d_vector }.to_java(Vector2f)] if "Polygon" == shape.to_s
      @shape = ("Physical::" + shape.to_s).constantize.new(*params)
    else
      @shape = shape
    end
    @body.set(@shape, @mass)
    set_body_position saved_body_position
    @target.set_position saved_position
    @target.move(saved_x, saved_y)
    self.damping = saved_damping
    self.angular_damping = saved_angular_damping 
  end
  
  def name=(name)
    @name = name
    setup_body
  end
  
  def add_to_world(world)
    world.add @body
    @world = world
  end
  
  def remove_from_world(world)
    world.remove @body
    @world = nil
  end
  
  def physical_debug_mode=(mode)
    if mode
      @target.add_behavior :DebugPhysical
    else
      @target.remove_behavior :DebugPhysical
    end
  end
  alias_method :set_physical_debug_mode, :physical_debug_mode=
  
  def movable=(movable)
    @body.moveable = movable
  end
  alias_method :set_movable, :movable=
  
  def movable?
    @body.moveable?
  end
  
  def damping
    @body.damping
  end
  
  def damping=(damping)
    @body.damping = damping
  end
  alias_method :set_damping, :damping=
  
  def angular_damping
    @angular_damping
  end
  
  def angular_damping=(damping)
    @angular_damping = damping
  end
  alias_method :set_angular_damping, :damping=
  
  def set_static_body
    @body.moveable = false
    @body.rotatable = false
    @body.is_resting = true
  end
  
  def gravity_effected=(effected)
    @body.gravity_effected = effected
  end
  alias_method :set_gravity_effected, :gravity_effected=
  
  def friction
    @body.friction
  end
  
  def friction=(friction)
    @body.friction = friction
  end
  alias_method :set_friction, :friction=
  
#  def get_colliding_game_objects(tangible_game_object)
#    # TODO: Tangibles only?
#    tangible_game_object
#  end
  
  def get_collision_events
    @world.get_contacts(@body)
  end
private
  def setup_body
    if @name
      @body = Body.new(@name, @shape, @mass)
    else
      @body = Body.new(@shape, @mass)
    end
    
    x = @body.position.x
    y = @body.position.y

    @body.set(@shape, @mass)
    @body.move(x, y)
  end
end