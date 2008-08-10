class BasicRenderManager < Gemini::GameObject
  def load(state)
    @state = state
    enable_listeners_for :before_render, :after_render
  end
  
  def render(graphics)
    notify :before_render
    state.manager(:game_object).game_objects.each { |game_object| game_object.draw if game_object.respond_to? :draw}
    notify :after_render
  end
end