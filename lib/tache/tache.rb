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
    @partials ||= PartialCollection.new
  end
  
  def partials=(hash)
    @partials = PartialCollection.new
    hash.each { |key, value| @partials[key] = value }
  end
  
  def escape(string)
    # RubyMotion doesn't have CGI class, i.e. CGI.escapeHTML(string)
    string.gsub(/[&\"<>]/, ENTITIES)
  end
  
  # TODO: Further testing. Used when retireving values in the context class,
  # ensuring that any Tache instances have the current context when retrieving
  # their values. This way, view methods have access to the current context.
  def scope(context)
    @prev_context = @context
    @context = context
    yield
  ensure
    @context = @prev_context
  end
  
  def self.compile(source)
    new.compile(source)
  end
            
  def self.render(source, view, partials = {})
    instance = compile(source)
    instance.partials = partials
    instance.render(view)
  end
  
  private
  
  def context
    @context ||= Context.new(self)
  end
  
  class PartialCollection < Hash
    def []=(key, value)
      super key, value.is_a?(Template) ? value : Template.new(value)
    end
  end
end