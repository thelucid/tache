class SimpleView < Tache
  def name
    "Chris"
  end
  
  def value
    10000
  end
  
  def taxed_value
    (value - (value * 0.4)).to_i
  end
  
  def in_ca
    true
  end
end

SimpleView