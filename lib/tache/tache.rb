class Tache
  ENTITIES = { '&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;' }
  
  def compile(source, options = {})
    @template = Template.new(source, options).compile
    self
  end
  
  def render(source_or_view = nil)
    case source_or_view
      when String then compile(source_or_view).render
      when nil then @template.render(context)
      else context.push(source_or_view) { |child| @template.render(child) }
    end
  end
  
  def partials
    @partials ||= PartialCollection.new(self)
  end
  
  def partials=(hash)
    @partials = PartialCollection.new(self)
    hash.each { |key, value| @partials[key] = value }
  end
  
  # TODO: test
  def partial(name)
    nil
  end
  
  def escape(string)
    # RubyMotion doesn't have CGI class, i.e. CGI.escapeHTML(string)
    string.gsub(/[&\"<>]/, ENTITIES)
  end
  
  def self.compile(source)
    new.compile(source)
  end
            
  def self.render(source, view = nil, partials = {})
    instance = compile(source)
    instance.partials = partials
    instance.render(view)
  end
  
  private
  
  def context
    @context ||= Context.new(self)
  end
  
  class PartialCollection < Hash
    def initialize(owner)
      @owner = owner
    end
    
    def [](key)
      value = super || begin
        partial = @owner.partial(key)
        partial && (self[key] = templatize(partial))
      end
    end
    
    def []=(key, value)
      super key, templatize(value)
    end
    
    private
    
    def templatize(value)
      value.is_a?(Template) ? value : Template.new(value)
    end
  end
end