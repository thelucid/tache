require 'tache'
require 'date'

class Tache::Safe < Tache
  def context
    @context ||= Context.make(self)
  end
  
  def respond_to_safe?(key)
    !GUARDED.include?(key) && respond_to?(key)
  end
  
  def to_tache
    self
  end
  
  def to_s
    ''
  end
  
  # Must happen after method definitions.
  GUARDED = public_instance_methods.map(&:to_s)
    
  class Context < Tache::Context
    def resolve(view, key)
      view = view.to_tache # TODO: revisit
      
      if view.respond_to?(:has_key?) && view.has_key?(key)
        view[key].to_tache
      elsif view.is_a?(Tache::Safe) && view.respond_to_safe?(key)
        value = view.method(key).call
        value.is_a?(Proc) ? value : value.to_tache
      else
        :_missing
      end
    end
  end
end

class Tache::Drop
  def [](key)
    present = !GUARDED.include?(key) && self.class.public_method_defined?(key)
    present ? send(key) : key_missing(key)
  end

  def has_key?(key)
    true
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

  # Must happen after method definitions.
  GUARDED = public_instance_methods.map(&:to_s)
end

# Give all core types a 'to_tache' method that returns self.
%w(String Array Hash Numeric Time Date DateTime TrueClass FalseClass NilClass).each do |klass|
  Kernel.const_get(klass).class_eval { define_method(:to_tache) { self } }
end

# A shortcut method that creates a drop class containing allowed_methods and a
# to_tache method that returns an instance of the drop class.
class Module
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