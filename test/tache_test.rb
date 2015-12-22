require File.expand_path('../helper', __FILE__)
require 'json'

class TacheTest < Test::Unit::TestCase
  test 'can have defaults in layout partials' do
    template = Tache::Template.new('Hello {{thing}}')
    
    result = Tache.render(
      '{{<layout}}{{/layout}}',
      nil,
      'layout' => 'Hello {{$planet}}planet{{/planet}}'
    )
    
    assert_equal 'Hello planet', result
  end
  
  test 'can override blocks in layout partials' do
    template = Tache::Template.new('Hello {{thing}}')
    
    result = Tache.render(
      '{{<layout}}{{$planet}}World!{{/planet}}{{/layout}}',
      nil,
      'layout' => 'Hello {{$planet}}planet{{/planet}}'
    )
    
    assert_equal 'Hello World!', result
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
      
      result = if ruby
        view.partials = { 'partial' => partial } if partial
        view.render
      else
        Tache.render(source, view, partial ? { 'partial' => partial } : {})
      end
      assert_equal txt, result, "Source: #{source.inspect}\nPartial: #{partial.inspect}"
    end
  end
end