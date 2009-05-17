class Pointer < Gemini::Behavior
  depends_on :Sprite
#  depends_on :Movable2d
#  depends_on :CollisionPoolAlgorithmTaggable
#  depends_on :WorldCollidable
  depends_on :ReceivesEvents
  
  declared_methods :mouse_movement, :start_click, :stop_click
  
  def load
#    add_tag :ui, :gui, :pointer
#    collides_with_tags :gui, :clickable
#    
    @target.handle_event :mouse_move do |message|
      mouse_movement(message)
    end
#    handle_event :start_click, :start_click
#    handle_event :stop_click, :stop_click
    
#    listen_for(:collided) do |event, continue|
#      event.collided_object.click if event.collided_object.respond_to? :click
#    end
  end
  
  def mouse_movement(message)
    vector = message.value
    @target.move(vector.location.x, vector.location.y)
  end
end