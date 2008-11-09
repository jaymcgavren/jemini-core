require 'set'

class RegionalTransitionEvent
  attr_accessor :region, :spatial
  def initialize(region, spatial)
    @region = region
    @spatial = spatial
  end
end

class Regional < Gemini::Behavior
  depends_on :Spatial
  attr_accessor :dimensions, :region_shape
  alias_method :set_dimensions, :dimensions=
  alias_method :set_region_shape, :region_shape=
  declared_methods :region_shape, :region_shape=, :set_region_shape, :dimensions, :dimensions=, :set_dimensions, :toggle_debug_mode, :within_region?
  
  # This is bad. We need a real collision system
  def load
    @target.enable_listeners_for :entered_region, :exited_region
    @target.move(0,0)
    @dimensions = Vector.new(1,1)
    @last_spatials_within = []
    @last_spatials_without = nil
    @last_spatials = []
    #TODO: SAVE: This should be turned on when requested.
#    @target.game_state.manager(:update).on_update do
#      spatials = @target.game_state.manager(:game_object).game_objects.select {|game_object| game_object.kind_of? Tangible}.compact
#      
#      spatials_within, spatials_without = spatials.partition {|spatial| within_region?(spatial)}
#      (spatials_within - @last_spatials_within).each do |spatial_within|
#        @target.notify :entered_region, RegionalTransitionEvent.new(self, spatial_within) if existed_last_update? spatial_within
#      end
#      @last_spatials_within = spatials_within
#      
#      unless @last_spatials_without.nil?
#        (spatials_without - @last_spatials_without).each do |spatial_without|
#          @target.notify :exited_region, RegionalTransitionEvent.new(self, spatial_without) if existed_last_update? spatial_without
#        end
#      end
#      @last_spatials_without = spatials_without
#      @last_spatials = spatials
#    end
  end
  
  def within_region?(spatial)
    half_width = dimensions.x / 2.0
    half_height = dimensions.y / 2.0
    ((@target.x - half_width) < spatial.x) && ((@target.x + half_width) > spatial.x) &&
    ((@target.y - half_height) < spatial.y) && ((@target.y + half_height) > spatial.y)
  end
  
  def existed_last_update?(game_object)
    @last_spatials.find {|previous_game_object| game_object == previous_game_object}
  end

  def toggle_debug_mode
    @debug_mode = !@debug_mode
    if @debug_mode
      @target.game_state.manager(:render).on_before_render do |graphics|
        old_color = graphics.color
        graphics.color = Color.new(0.0, 1.0, 0.0, 0.3).native_color
        half_width = dimensions.x / 2.0
        half_height = dimensions.y / 2.0
        graphics.fill_rect(@target.x - half_width, @target.y - half_height, dimensions.x, dimensions.y)
        graphics.color = old_color
      end
    else
      @target.game_state.manager(:render).remove_before_draw self
    end
  end
end