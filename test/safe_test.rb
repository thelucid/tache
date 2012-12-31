require File.expand_path('../helper', __FILE__)

require 'tache/safe'

class SafeTest < Test::Unit::TestCase
  def setup
    @safe_tache = Class.new(Tache::Safe) do
      def present
        "I'm here baby!"
      end
    end
    
    @drop_class = Class.new(Tache::Drop) do
      def present
        "I'm here baby!"
      end
    end
    
    @verbose_drop_class = Class.new(Tache::Drop) do
      def present
        "I'm here baby!"
      end

      def key_missing(key)
        "[missing: #{key}]"
      end

      def to_s
        "[DropClass]"
      end
    end
  end

  test 'filters guarded methods' do
    source = 'present: {{present}}, inspect: {{inspect}}, class: {{class}}'
    view = @safe_tache.compile(source)
    assert_equal "present: I'm here baby!, inspect: , class: ", view.render
  end

  test 'can use drops to filter guarded methods' do
    source = 'Hello {{thing}}, present: {{drop.present}}, inspect: {{drop.inspect}}'
    view = Tache::Safe.compile(source)
    assert_equal  "Hello World, present: I'm here baby!, inspect: ", 
                  view.render('thing' => 'World', 'drop' => @drop_class.new)
  end
  
  test 'can use key_missing on drops' do
    source = 'Hello {{thing}}, present: {{drop.present}}, inspect: {{drop.inspect}}'
    view = Tache::Safe.compile(source)
    assert_equal  "Hello World, present: I'm here baby!, inspect: [missing: inspect]",
                  view.render('thing' => 'World', 'drop' => @verbose_drop_class.new)
  end
  
  test 'can use to_s on drops' do
    source = 'Hello {{thing}}, present: {{drop.present}}, drop: {{drop}}'
    view = Tache::Safe.compile(source)
    assert_equal  "Hello World, present: I'm here baby!, drop: [DropClass]",
                  view.render('thing' => 'World', 'drop' => @verbose_drop_class.new)
  end
end