require 'tag_manager'
require 'basic_physics_manager'

class MainState < Gemini::BaseState 
  def load
    set_manager :physics, create_game_object(:BasicPhysicsManager)
    set_manager :tag, create_game_object(:TagManager)
    
    load_keymap :MainGameKeymap
    
    car = create_game_object :Car
    car.set_position(400,400)
    
#    gangster = create_game_object :Gangster
#    gangster.set_position(300,300)
#    gangster.set_rotation_target car

    # Load map data
    map_data = File.readlines('data/test_map.txt')
    map_data.reject! {|line| line =~ /^\s*#/ || line.strip.empty?}
    map_tiles = []
    
    map_data.each do |line| 
      next if line =~ /^layer/ #skip for now
      parts = line.chomp.split('_')
      name, tangible, rotation, flipping, x, y = parts
      rotation, x, y = rotation.to_i, x.to_i, y.to_i
      tangible = "true" == tangible ? true : false
      puts "name: #{name}, tangible: #{tangible}, rotation: #{rotation}, flipping: #{flipping}, x: #{x}, y: #{y}"
      if tangible
        tile = create_game_object(:StaticSprite, "#{name}.png", x+32, y+32, 64, 64)
        tile.rotation = rotation
      else
        tile = create_game_object :GameObject
        tile.add_behavior :Sprite
        tile.image = "#{name}.png"
        tile.move(x+32, y+32)
        tile.image_rotation = rotation
      end
      
      if "horizontal" == flipping
        tile.flip_horizontally
      elsif "vertical" == flipping
        tile.flip_vertically
      end
      
      map_tiles << tile
    end
    
    # uncomment to enable profiler (needs keymap too)
#    quitter = create_game_object :GameObject
#    quitter.add_behavior :RecievesEvents
#    quitter.handle_event :quit do
#      Profiler__::print_profile(STDERR) if $profiling
#      Java::java::lang::System.exit 0
#    end
  end
end
