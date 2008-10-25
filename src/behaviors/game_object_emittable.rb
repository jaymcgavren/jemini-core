class GameObjectEmittable < Gemini::Behavior
  declared_methods :emitting_game_object_name=, :set_emitting_game_object_name, :emit_game_object
  attr_accessor :emitting_game_object_name
  alias_method :set_emitting_game_object_name, :emitting_game_object_name=
  def load
    @target.enable_listeners_for :emit_game_object
  end
  
  def emit_game_object(message=nil)
    game_object = @target.game_state.create_game_object @emitting_game_object_name
    @target.notify :emit_game_object, game_object
  end
end