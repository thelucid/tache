require File.expand_path('../helper', __FILE__)
require 'json'

class TacheTest < Test::Unit::TestCase
  test "hello world" do
    template = Tache.compile("Hello {{thing}}")
    assert_equal "Hello World", template.render({ 'thing' => 'World' })
  end
  
  Dir.glob("test/fixtures/*.mustache") do |file|
    basename  = File.basename(file, '.mustache')
    basepath  = File.join(File.dirname(file), basename)
    
    test basename do
      source  = File.read("#{basepath}.mustache")      
      txt     = File.read("#{basepath}.txt")
      json    = File.read("#{basepath}.json")     if File.exists?("#{basepath}.json")
      ruby    = File.read("#{basepath}.rb")       if File.exists?("#{basepath}.rb")
      partial = File.read("#{basepath}.partial")  if File.exists?("#{basepath}.partial")
      
      view = if json
        JSON.parse(json)
      elsif ruby
        proc = Proc.new {}
        klass = eval(ruby, proc.binding, "#{basepath}.rb")
        klass.compile(source)
      end      
      
      if ruby
        view.partials = { 'partial' => partial } if partial
        assert_equal txt, view.render
      else
        assert_equal txt, Tache.render(source, view, partial ? { 'partial' => partial } : {})
      end
    end
  end
end