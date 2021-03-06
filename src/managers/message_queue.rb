require 'thread'
module Jemini
  
  # Message object that is posted to the MessageQueue.
  class Message
    attr_accessor :name, :value, :delta, :to
    
    def initialize(name, value, delta=nil, to=nil)
      @name  = name
      @value = value
      @delta = delta
      @to    = to
    end
  end
  
  class MessageQueue < Jemini::GameObject
    def load
      @listeners = Hash.new {|h,k| h[k] = []}
      @messages = Queue.new
    end

    def process_messages(delta)
      until @messages.empty?
        message = @messages.shift
        message.delta = delta
        
        @listeners[message.name].each do |listener|
          begin
            if message.to.nil?
              listener[1].call(message)
            else
              listener[1].call(message) if listener[0].respond_to?(:handles_events_for?) && listener[0].handles_events_for?(message.to)
            end
          rescue Exception => e
            # Replace this with a logger
            $stderr << "Error in callback #{listener[1]} for key: #{listener[0]}\n#{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
            java.lang.System.exit(1)
          end
        end
      end
    end

    def post_message(message)
      @messages << message
    end

    # Listeners are registered on a certain type of message.  This type is arbitrary
    # and can be any symbol.  The second parameter is a key that is used to identify
    # the callback when it is removed.  The third parameter is the callback object
    # which must be a proc.  Alternatively, the second parameter may be omitted and a
    # block passed in its place.
    def add_listener(type, key, callback=nil, &block)
      @listeners[type.to_sym] << [key, callback || block]
    end

    def remove_listener(type, key)
      @listeners[type.to_sym].delete_if {|listener| listener.first == key}
    end
  end
end