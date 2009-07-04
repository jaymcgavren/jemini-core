class TankWheel < Gemini::GameObject
  has_behavior :PhysicalSprite
  has_behavior :Taggable
  
  TURN_RATE = 0.05
  
  def load
    set_image @game_state.manager(:render).get_cached_image(:tank_wheel)
    set_shape :Circle, image.width / 2.0
    set_friction 5000.0
    set_mass 5.0
    set_angular_damping 50.0
    set_angular_velocity 0.0
    set_restitution 0.25
  end

  def turn(power)
    apply_angular_velocity power * TURN_RATE
  end
end