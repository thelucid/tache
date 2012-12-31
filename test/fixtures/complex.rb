class ComplexView < Tache
  def header
    "Colors"
  end
  
  def item
    [
      { 'name' => "red", 'current' => true, 'url' => "#Red" },
      { 'name' => "green", 'current' => false, 'url' => "#Green" },
      { 'name' => "blue", 'current' => false, 'url' => "#Blue" }
    ]
  end
  
  def link
    !context['current']
  end
  
  def list
    !item.empty?
  end
  
  def empty
    item.empty?
  end
end

ComplexView