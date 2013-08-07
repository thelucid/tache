require 'test/unit'
require 'tache'

class Test::Unit::TestCase
  def self.test(name, &block)
    name = 'test_' << name.tr(' ', '_').gsub(/\W+/, '')
    defined = instance_method(name) rescue false
    raise "'#{name}' already defined in #{self}" if defined
    block ||= proc { assert_block('Pending'){ false } }
    define_method(name, &block)
  end
end