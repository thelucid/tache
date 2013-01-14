class CoercionView < Tache
  def to_tache_value
    "I'm the daddy!"
  end
  
  def ok
    'Default OK'
  end
  
  def item
    OpenStruct.new(to_tache_value: 'The thing')
  end
  
  def items
    [ OpenStruct.new(to_tache_value: Tache::Template.new("<li>First: {{ok}}</li>\n"), ok: 'Yep'),
      OpenStruct.new(to_tache_value: Tache::Template.new("<li>Second: {{ok}}</li>\n")) ]
  end
  
  def string_items
    ["Just a string, ", "And another"]
  end  
end

CoercionView