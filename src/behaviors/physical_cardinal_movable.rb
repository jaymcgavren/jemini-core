# A CardinalMovable that interacts with the physics manager.
# See the API for CardinalMovable for method descriptions.
# TODO: Allow disabling of diaganol easily
# TODO: Allow disabling of directions
# TODO: Allow speed limit per axis
# TODO: Allow speed limit per direction
class PhysicalCardinalMovable < Jemini::Behavior
  NORTH = :north
  EAST  = :east
  SOUTH = :south
  WEST  = :west
  NORTH_EAST = :north_east
  SOUTH_EAST = :south_east
  SOUTH_WEST = :south_west
  NORTH_WEST = :north_west
  DIAGONAL_DIRECTIONS = [NORTH_EAST, SOUTH_EAST, SOUTH_WEST, NORTH_WEST]
  CARDINAL_DIRECTIONS = [NORTH, EAST, SOUTH, WEST] + DIAGONAL_DIRECTIONS
  DIRECTION_TRANSLATION_IN_DEGREES = []
  
  depends_on :Physical
  depends_on :HandlesEvents
  attr_accessor :facing_direction
  wrap_with_callbacks :facing_direction=, :set_facing_drection
  
  def load
    @facing_direction = NORTH
    @allowed_directions = CARDINAL_DIRECTIONS.dup
    @cardinal_speed = 25
    @game_object.on_update do
      @game_object.add_velocity @cardinal_velocity if @moving
    end
  end
  
  def facing_direction=(direction)
    if @allowed_directions.include? direction
      if @moving && orthogonal_directions?(@facing_direction, direction)
        diagonal_direction = begin
                               "#{self.class}::#{@facing_direction.to_s.upcase}_#{direction.to_s.upcase}".constantize
                             rescue
                               "#{self.class}::#{direction.to_s.upcase}_#{@facing_direction.to_s.upcase}".constantize
                             end
        @facing_direction = diagonal_direction
      else
        @facing_direction = direction
      end
    end
  end
  alias_method :set_facing_direction, :facing_direction=
  
  def constrain_direction(directions)
    directions = [directions] unless directions.kind_of? Array
    directions.each
    directions.each { |direction| @allowed_directions.delete direction }
  end
  
  def begin_cardinal_movement(message)
    direction = message.value
    return unless @allowed_directions.include? direction
    set_facing_direction direction
    @moving = true
    @cardinal_velocity = direction_to_polar_vector(@facing_direction)
  end
  
  def end_cardinal_movement(message)
    direction = message.value
    @facing_direction = other_direction(@facing_direction, direction) if diagonal_direction? @facing_direction
    if @facing_direction == direction
      @cardinal_velocity = Vector.new(0,0)
      @moving = false
    else
      @cardinal_velocity = direction_to_polar_vector(@facing_direction)
    end
  end

private

  def direction_to_polar_vector(direction)
    angle = case direction
            when NORTH
              0
            when NORTH_EAST
              45
            when EAST
              90
            when SOUTH_EAST
              135
            when SOUTH
              180
            when SOUTH_WEST
              225
            when WEST
              270
            when NORTH_WEST
              315
            end
    Vector.from_polar_vector(@cardinal_speed, angle)
  end
  
  def diagonal_direction?(direction)
    DIAGONAL_DIRECTIONS.include? direction
  end
  
  def other_direction(diagonal_direction, direction)
    diagonal_direction.to_s.sub(direction.to_s, '').sub('_', '').to_sym
  end
  
  def orthogonal_directions?(direction_a, direction_b)
    ([NORTH, SOUTH].include?(direction_a) && [EAST, WEST].include?(direction_b)) ||
    ([NORTH, SOUTH].include?(direction_b) && [EAST, WEST].include?(direction_a))
  end
end