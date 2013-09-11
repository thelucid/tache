# Note: Currently requires cgi be made available to the target app via
# MotionBundler (for html escaping). We could just rewrite to not use the
# escape method using:
#
#   ENTITIES = { '&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;' }
#   def escape
#     string.gsub(/[&\"<>]/, ENTITIES)
#   end

class Tache
  def compile(source, options = {})
    @compiled = Template.new(source, options).compile
    self
  end
  
  def render(source_or_view = nil)
    case source_or_view
      when String then Template.new(source_or_view).render(context)
      when nil then @compiled.render(context)
      else context.push(source_or_view) { |child| @compiled.render(child) }
    end
  end
  
  def partials
    @partials ||= PartialCollection.new
  end
  
  def partials=(hash)
    @partials = PartialCollection.new
    hash.each { |key, value| @partials[key] = value }
  end
  
  def escape(str)
    CGI.escapeHTML(str)
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
    @context ||= Context.make(self)
  end
  
  class PartialCollection < Hash
    # TODO: Lazy compiling reader vs. compiling on write?
    def []=(key, value)
      super key, value.is_a?(Template) ? value : Template.new(value)
    end
  end
end