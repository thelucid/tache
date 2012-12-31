require 'test/unit'
require 'tache'

class Test::Unit::TestCase
  def self.test(name, &block)
    define_method 'test_' << name.tr(' ', '_').gsub(/\W+/, ''), &block
  end
end