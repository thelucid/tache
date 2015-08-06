# TODO: This means that subclasses have to override has_key? if they want to
# support key_missing. The other option is to return :missing from
# key_missing by default and stipulate that subclasses must call super if
# they can't find the key, that does however mean a couple of extra method
# calls, one to [] and one to key_missing, even if key not supported. Is
# extra overhead worth it for being able to override just key_missing?
# 
# Example:
#   def has_key?(key)
#     super || @thingy.respond_to?(key)
#   end
#   
#   def key_missing(key)
#     @thingy.send(key)
#   end
# 
# Another option would be to have a handles_key? method akin to responds_to_missing?

class Tache::Safe < Tache
  def context
    @context ||= Context.new(self)
  end

  def has_key?(key)
    allowed_method?(key)
  end
  
  def [](key)
    allowed_method?(key) ? send(key) : key_missing(key)
  end

  def key_missing(key)
    nil
  end
  
  def to_s
    ''
  end
  
  private
  
  # Must happen after method definitions.
  GUARDED = begin
    methods = public_instance_methods.map(&:to_s)
    if methods.respond_to?(:to_set)
      methods.to_set
    else
      # Note: RubyMotion doesn't do sets so using hash.
      methods.inject({}) { |hash, key| hash[key] = true; hash }
    end
  end
  
  def allowed_method?(key)
    !GUARDED.include?(key) && self.class.public_method_defined?(key)
  end
    
  class Context < Tache::Context
    def push(view, &block)
      super tacheify(view), &block
    end
    
    def resolve(view, key)
      if view.respond_to?(:has_key?) && view.has_key?(key)
        value = view[key]
        return value if value == :missing 
        view.is_a?(Tache::Safe) && value.respond_to?(:call) ? value : tacheify(value)
      else
        :missing
      end
    end
    
    private
    
    def tacheify(object)
      object = object.to_tache if object.respond_to?(:to_tache)
      
      case object
      when Tache::Safe, String, Array, Hash, Numeric, Time, TrueClass, FalseClass, NilClass, Enumerable
        object
      else
        raise "Unsafe object type: #{object.inspect}"
      end
    end
  end
end