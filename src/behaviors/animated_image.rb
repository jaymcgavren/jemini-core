#A 2D image with mutltiple frames of animation.
class AnimatedImage < Jemini::Behavior
  DEFAULT_MILLISECONDS_PER_UPDATE = 250 # quarter of a second
  java_import 'org.newdawn.slick.Image'
  java_import 'org.newdawn.slick.Animation'

  depends_on :DrawableImage
  depends_on :Updates
  
  attr_reader :animations
  attr_accessor :animation_speed
  
  def load
    @animations_per_action  = {}
    @current_action         = 'default'
    @animation_timer        = 0
    @frame_number           = 1
    @pulsing                = false
    @repeat                 = true
    @animation_speed        = DEFAULT_MILLISECONDS_PER_UPDATE
    game_object.on_update do |delta|
      update_animation(delta)
      @pulsed_this_frame = false
    end
  end

  def animate(action)
    self.current_action = action.to_s
    @repeat = false
  end

  def animate_pulse(action, delta)
    self.current_action = action unless @current_action.to_s == action.to_s
    @pulsing = true
    @pulsed_this_frame = true
    update_animation(delta) 
  end

  def animate_cycle(action)
    animate action
    @repeat = true
  end

  def animate_as(noun)
    @noun = noun
    noun_regex = Regexp.new(noun.to_s)
    all_images_for_noun = game_state.manager(:resource).image_names.select {|image| image.to_s =~ noun_regex }
    animations_for_noun = all_images_for_noun.map {|image_name| image_name.to_s.sub("#{@noun}_", '')}
    @animations = animations_for_noun.map {|animation| animation.sub(/\d/, '').to_sym}.uniq
    @animations.each do |action|
      action_regex = Regexp.new(action.to_s)
      animations = all_images_for_noun.select {|numbered_animation| numbered_animation.to_s =~ action_regex }
      @animations_per_action[action.to_s] = animations #.map {|a| a.to_s } 
    end
  end

private

  def current_action=(action)
    @animation_timer   = 0
    @current_action    = action
    @frame_number      = 1 # one based
    @pulsing           = false
    @pulsed_this_frame = false
    @game_object.image      = @animations_per_action[action.to_s].first
  end

  def update_animation(delta)
    return if @noun.nil?
    self.current_action = 'default' if @pulsing && !@pulsed_this_frame

    @animation_timer += delta

    return if @animation_timer < @animation_speed

    @frame_number = @animation_timer / @animation_speed

    animations = @animations_per_action[@current_action.to_s]
    new_frame = animations[@frame_number]
    if new_frame
      @game_object.image = new_frame
    elsif @repeat
      self.current_action = @current_action
    else
      self.current_action = 'default'
    end
  end
end