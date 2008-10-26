module Gemini
  class MethodExistsError < Exception; end
  
  class Behavior
    attr_reader :reference_count, :target

    @@depended_on_by = Hash.new{|h,k| h[k] = []}
    def self.add_to(target)
      unless instance = @@depended_on_by[target].find {|behavior| behavior.class == self}
        instance = self.new(target)
        @@depended_on_by[target] << instance
      end
      instance.add_reference_count
      instance
    end
    
    def self.remove_from(target)
      if instance = @@depended_on_by[target.class].find {|behavior| behavior.class == self}
        instance.remove_reference_count
        if 0 == instance.reference_count
          @@depended_on_by[target.class].delete_if {|behavior| behavior.class == self}
          instance.send(:delete)
          #@@depended_on_by.delete target if @@depended_on_by[target].empty?
        end
      end
    end
    
    def self.method_added(method)
      if callback_methods_to_wrap.member? method
        begin
          return if callback_methods_wrapped.member? method #instance_method(:"wrapped_#{method}") #&& wrapped_methods.member?(method)
        rescue NameError; end #Intentionally swallow, this section is to prevent infinite recursion
        callback_methods_wrapped << method
        alias_method :"wrapped_#{method}", method
        arity = instance_method(:"wrapped_#{method}").arity
        if arity.abs > 0
          args = (1..arity.abs).inject([]){|args, i| args << "arg#{i}" }
          args[-1].insert(0,"*") if arity < 0
        end
        if match = /^(.*)=$/.match(method.to_s)
          method_name = match[1]
          code = <<-ENDL
            def #{method}(#{args})
              callback_abort = CallbackStatus.new
              @target.notify :before_#{method_name}_changes, callback_abort
              if callback_abort.continue?              
                self.wrapped_#{method}(#{args})
                @target.notify :after_#{method_name}_changes
              end
            end
          ENDL
          wrapped_methods << "before_#{method_name}_changes"
          wrapped_methods << "after_#{method_name}_changes"
        else
          code = <<-ENDL
            def #{method}(#{(args.join(",") + ",") if args} &block)
              callback_abort = CallbackStatus.new
              @target.notify :before_#{method}, callback_abort
              if callback_abort.continue?              
                self.wrapped_#{method}(#{(args.join(",") + ",") if args} &block)
                @target.notify :after_#{method}
              end
            end
          ENDL
          wrapped_methods << "before_#{method}"
          wrapped_methods << "after_#{method}"
        end
        self.class_eval(code, __FILE__, __LINE__)
      else
        super
      end
    end
    
  protected
  
    def self.depends_on(behavior)
      require "behaviors/#{behavior.underscore}"
      add_dependency(behavior)
    end

    def self.depends_on_kind_of(behavior)
      add_kind_of_dependency(behavior)
    end
    
    def self.wrap_with_callbacks(*args)
      @@callback_methods_to_wrap[self].concat args
    end
    
    @@callback_methods_to_wrap = Hash.new {|h,k| h[k] = []}
    def self.callback_methods_to_wrap
      @@callback_methods_to_wrap[self]
    end
    
    @@callback_methods_wrapped = Hash.new {|h,k| h[k] = []}
    def self.callback_methods_wrapped
      @@callback_methods_wrapped[self]
    end
    
    @@wrapped_methods = Hash.new {|h,k| h[k] = []}
    def self.wrapped_methods
      @@wrapped_methods[self]
    end
    
  private
    
    def self.new(*args)
      super
    end
    
    @@method_list = Hash.new{|h,k| h[k] = []}
    def self.declared_methods(*methods)
      @@method_list[self] = methods
    end
    def self.declared_method_list
      @@method_list[self]
    end

    @@behavior_dependencies = Hash.new{|h,k| h[k] = []}
    def self.dependencies
      @@behavior_dependencies[self]
    end
    
    def self.add_dependency(behavior)
      @@behavior_dependencies[self] << behavior
    end
    
    @@kind_of_behavior_dependencies = Hash.new{|h,k| h[k] = []}
    def self.kind_of_dependencies
      @@kind_of_behavior_dependencies[self]
    end
    
    def self.add_kind_of_dependency(behavior)
      @@kind_of_behavior_dependencies[self] << behavior
    end
    
    def initialize(target)
      @target = target
      @dependant_behaviors = []
      @reference_count = 0
      
      self.class.dependencies.each do |dependant_behavior|
        begin
          dependant_behavior_class = Object.const_get(dependant_behavior)
        rescue NameError
          raise "Cannot load dependant behavior '#{dependant_behavior}' in behavior '#{self.class}'"
        end
        dependant_behavior_instance = dependant_behavior_class.add_to(@target) unless @target.kind_of? dependant_behavior_class
        @dependant_behaviors << dependant_behavior_instance
      end
      
      behavior_list = @target.send(:instance_variable_get, :@__behaviors)
      return unless behavior_list[self.class.name.to_sym].nil?
      behavior_list[self.class.name.to_sym] = self 
      
      @dependant_behaviors.each do |dependant_behavior|
        behavior_list[dependant_behavior.class.name.to_sym] = dependant_behavior if behavior_list[dependant_behavior.class.name.to_sym].nil? 
      end

#      self.class.kind_of_dependencies.each do |dependant_behavior|
#        dependency = dependant_behavior.constantize
#        next if behavior_list.find {|behavior| behavior.last.kind_of?(dependency)}
#        
#        raise "Dependant behavior '#{dependant_behavior}' was not found on class #{self.class}" 
#      end

      self.class.declared_method_list.each do |method|
        #TODO: Tell us which behavior is being overridden
        #TODO: Allow for overriding
        raise MethodExistsError.new("Error while adding the behavior #{self.class}. The method #{method} already exists on game object #{@target}.") if @target.respond_to? method
        if method.to_s =~ /=/
          code = <<-ENDL
          def #{method}(arg)
            @__behaviors[:#{self.class}].#{method}(arg)
          end
          ENDL
        else
          code = <<-ENDL
          def #{method}(*args, &blk)
            @__behaviors[:#{self.class}].#{method}(*args, &blk)
          end
          ENDL
        end
        @target.send(:instance_eval, code, __FILE__, __LINE__)
      end

      self.class.wrapped_methods.each do |method|
        @target.enable_listeners_for method
      end

      self.load
    end

    def delete
      unload
      @dependant_behaviors.each {|dependant| dependant.class.remove_from(@target)}
      self.class.declared_method_list.each do |method|
        begin
          target_class = class <<@target; self; end
          target_class.send(:remove_method, method)
        rescue NameError
          # just continue if this method isn't there anymore
        end
      end
    end
    
  public
    
    def set_event_aliases(mappings, block)
      if mappings.kind_of? Hash
        mappings.each do |event, event_alias|
          @target.handle_event(event_alias) do |message|
            send(event, message)
          end
        end
      else mappings.kind_of? Symbol
        @target.handle_event(mappings) do |message|
          message = message.dup
          send(block.call(message), message)
        end
      end
    end
    
    def add_reference_count
      @reference_count += 1
    end
    
    def remove_reference_count
      @reference_count -= 1
    end

    def load; end
    def unload; end
  end
  
  class CallbackStatus
    def continue?
      true
    end
  end
end