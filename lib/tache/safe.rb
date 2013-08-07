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
    def push(view, &block)
      super view.to_tache, &block
    end
    
    def resolve(view, key)
      if view.respond_to?(:has_key?) && view.has_key?(key)
        view[key] == :_missing ? :_missing : view[key].to_tache
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

  # TODO: This means that subclasses have to override has_key? if they want to
  # support key_missing. The other option is to return :_missing from
  # key_missing by default and stipulate that subclasses must call super if
  # they can't find the key, that does however mean a couple of extra method
  # calls, one to [] and one to key_missing, even if key not supported. Is
  # extra overhead worth it for being able to override just key_missing?
  def has_key?(key)
    !GUARDED.include?(key) && self.class.public_method_defined?(key)
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