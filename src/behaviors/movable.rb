# Enables simple movement
# This movement is not coupled to any physics behavior
# TODO: Consider adding #move_with(spline) method
class Movable < Jemini::Behavior
  DEFAULT_DESTINATION_ACCURACY = 0.1
  
  depends_on :Spatial
  depends_on :Updates
  wrap_with_callbacks :move, :moveable_speed=
  listen_for :movement, :movable_arrival
  
  attr_accessor :movable_speed, :movable_destination_accuracy
  alias_method :set_movable_speed, :movable_speed
  
  def load
    @movable_speed = 0.01
    @movable_destination_accuracy = DEFAULT_DESTINATION_ACCURACY
    @game_object.on_update {|delta| update_movement delta }
  end

  # move at a direction indefinitely
  def move(angle_or_polar, speed=nil)
    @destination = nil
    if angle_or_polar.kind_of? Numeric
      self.movable_speed = speed unless speed.nil?       # force the callbacks
      @movement = Vector.from_polar_vector(movable_speed, angle_or_polar)
    else
      angle = angle_or_polar.angle_from(@game_object.position)
      @movement = Vector.from_polar_vector(movable_speed, angle)
      self.movable_speed = @movement.magnitude
      warn "Vector given in first arg means speed of #{speed} is ignored." if speed
    end
  end

  # move to a destination
  def move_to(desired_location, speed=nil)
    self.movable_speed = speed if speed
    move desired_location.angle_from(@game_object.position), movable_speed
    @destination = desired_location
  end

  def movement_direction
    return nil if @movement.nil?
    @movement.angle_from(Vector.new(0.0, 0.0))
  end

private
  def update_movement(delta)
    return unless @movement
    new_position = @game_object.position + Vector.new(@movement.x * delta, @movement.y * delta)
    
    if @destination
      move_to_destination new_position
    else
      move_normally_with new_position
    end
  end

  def move_to_destination(new_position)
    new_position = @destination if overshot_destination?(new_position)
    move_normally_with new_position # may seem like a possible no-op from above, but will kick off callbacks for Movable and Spatial

    if @game_object.position.near?(@destination, @movable_destination_accuracy)
      @destination = nil
      @movement    = nil
      @game_object.notify :movable_arrival
    end
  end

  def move_normally_with(new_position)
    @game_object.position = new_position
    @game_object.notify :movement
  end

  def overshot_destination?(new_position)
    previous_distance = @game_object.position.distance_from(@destination).abs
    new_distance      = new_position.distance_from(@destination).abs

    new_distance > previous_distance
  end
end