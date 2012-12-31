class EscapedView < Tache
  def title
    "Bear > Shark"
  end
  
  def entities
    "&quot; \"'<>/"
  end
end

EscapedView