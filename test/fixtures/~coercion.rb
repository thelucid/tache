class SimpleRenderable
  def initialize(value)
    @value = value
  end
  
  def to_s
    @value
  end
end

class DefaultTemplateRenderable
  def initialize(source)
    @source = source
  end
  
  def to_s
    Tache::Template.new(@source)
  end
end

class OkTemplateRenderable
  def initialize(source)
    @source = source
  end
  
  def ok
    'Yep'
  end
  
  def to_s
    Tache::Template.new(@source)
  end
end

class CoercionView < Tache
  def to_s
    "I'm the daddy!"
  end
  
  def ok
    'Default OK'
  end
  
  def item
    SimpleRenderable.new('The thing')
  end
  
  def items
    [ OkTemplateRenderable.new("<li>First: {{ok}}</li>\n"),
      DefaultTemplateRenderable.new("<li>Second: {{ok}}</li>\n") ]
  end
  
  def empty_items
    []
  end
  
  def string_items
    ["Just a string, ", "And another"]
  end
end

CoercionView