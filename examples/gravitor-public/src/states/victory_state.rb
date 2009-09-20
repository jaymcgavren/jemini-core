class VictoryState < Jemini::BaseState
  def load
    set_manager :sound, create_game_object(:SoundManager)
    
    background = create_game_object :GameObject, :Sprite
    background.set_image "victory_background.png"
    background.move_by_top_left(0,0)
    
    load_keymap :MouseKeymap
    
    exiter = create_game_object :GameObject, :ReceivesEvents
    exiter.handle_event :mouse_button1_released do
      switch_state :MenuState
    end
    
    manager(:sound).loop_song :gravitor_victory
  end
end