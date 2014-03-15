require File.expand_path('../helper', __FILE__)

class TemplateTest < Test::Unit::TestCase
  def setup
    @tache_klass = Class.new(Tache) do
      def thing
        'World'
      end
      
      def lambda_thing
        proc { Tache::Template.new("*{{thing}}*") }
      end
    end
  end
  
  test 'can compile' do
    template = Tache::Template.new('Hello {{thing}}')
    
    assert_equal false, template.compiled?    
    template.compile
    assert_equal true, template.compiled?
  end
  
  test 'can render after compiling' do
    template = Tache::Template.new('Hello {{thing}}')    
    template.compile
    
    assert_equal 'Hello World', template.render(Tache::Context.make(@tache_klass.new))
  end
  
  test 'can lazily compile at render' do
    template = Tache::Template.new('Hello {{thing}}')
    
    assert_equal false, template.compiled?
    assert_equal 'Hello World', template.render(Tache::Context.make(@tache_klass.new))
    assert_equal true, template.compiled?
  end
  
  test 'can specify tags' do
    template = Tache::Template.new('Hello <%thing%>', :tags => %w(<% %>))    
    
    assert_equal 'Hello World', template.render(Tache::Context.make(@tache_klass.new))
  end
  
  test "can return template from lambda" do
    template = Tache::Template.new('Hello {{lambda_thing}}')    
    template.compile
    
    assert_equal 'Hello *World*', template.render(Tache::Context.make(@tache_klass.new))
  end
end