# TODO: This means that subclasses have to override has_key? if they want to
# support key_missing. The other option is to return :_missing from
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
    @context ||= Context.make(self)
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
  
  def to_tache
    self
  end
  
  def to_s
    ''
  end
  
  private
  
  # Must happen after method definitions.
  GUARDED = public_instance_methods.map(&:to_s)
  
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
        return value if value == :_missing 
        view.is_a?(Tache::Safe) && value.respond_to?(:call) ? value : tacheify(value)
      else
        :_missing
      end
    end
    
    private
    
    def tacheify(object)
      return object.to_tache if object.respond_to?(:to_tache)
      
      case object
      when String, Array, Hash, Numeric, Time, DateTime, TrueClass, FalseClass, NilClass
        object
      else
        raise 'Unsafe object type when using Tache::Safe'
      end
    end
  end
end

# For legacy support. Depreciate.
class Tache::Drop < Tache::Safe
end

# Adds a shortcut method that creates a drop class containing allowed_methods
# and a to_tache method that returns an instance of the drop class.
# 
# Example:
# 
#   class MyObject
#     include Tache::Safe::Auto
#     tache :my_method, :my_other_method
#   end
# 
module Tache::Safe::Auto
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def tache(*allowed_methods)
      drop_class = Class.new(Tache::Drop) do
        def initialize(object)
          @object = object
        end
        allowed_methods.each do |sym|
          define_method sym do
            @object.send sym
          end
        end
      end
    
      self.const_set 'TacheDrop', drop_class    
      define_method(:to_tache) { drop_class.new(self) }
    end
  end
end