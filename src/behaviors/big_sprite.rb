require 'behaviors/drawable'

#Simplistic implementation of a big image to be used as a background image.  See Sprite.
class BigSprite < Drawable
  include_class 'org.newdawn.slick.BigImage'
  attr_accessor :image
  depends_on :Spatial
  attr_accessor :image, :color, :texture_coords, :image_size
  alias_method :set_image_size, :image_size=
  
  def load
    @color = Color.new(1.0, 1.0, 1.0, 1.0)
    @texture_coords = [Vector.new(0.0, 0.0), Vector.new(1.0, 1.0)]
  end
  
  def draw(graphics)
    half_width = @image.width / 2
    half_height = @image.height / 2
    center_x = @game_object.x - half_width
    center_y = @game_object.y - half_height
    unless 0 == @image.rotation
      graphics.rotate @game_object.x, @game_object.y, @image.rotation
    end
    @image.draw(center_x, center_y, @game_object.x + half_width, @game_object.y + half_height,
                @texture_coords[0].x * @image.width, @texture_coords[0].y * @image.height, @texture_coords[1].x * @image.width, @texture_coords[1].y * @image.height,
                @color.native_color)
    graphics.reset_transform
  end
  
  def move_by_top_left(move_x_or_vector, move_y = nil)
    half_width = @game_object.image_size.x / 2
    half_height = @game_object.image_size.y / 2
    if move_y.nil?
      @game_object.move(move_x_or_vector.x + half_width, move_x_or_vector.y + half_height)
    else
      @game_object.move(move_x_or_vector + half_width, move_y + half_height)
    end
  end
  
  #Takes a BigImage, but is otherwise identical to Sprite.set_image.
  def image=(sprite_name)
    if sprite_name.kind_of? BigImage
      @image = sprite_name
    else
      @image = BigImage.new(Resource.path_of(sprite_name))
    end
    set_image_size(Vector.new(@image.width, @image.height))
  end
  alias_method :set_image, :image=
end