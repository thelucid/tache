require 'tache'
require 'date'

# Give all core types a 'to_tache' method that returns self.
%w(String Array Hash Numeric Time Date DateTime TrueClass FalseClass NilClass).each do |klass|
  Kernel.const_get(klass).class_eval { define_method(:to_tache) { self } }
end
  
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