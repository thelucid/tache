class DotNotationPrice
  def value
    200
  end
  
  def vat
    (value * 0.2).to_i
  end
  
  def currency
    { 'symbol' => '$',
      'name' => 'USD' }
  end
end

class DotNotationView < Tache
  def name
    "A Book"
  end
  
  def authors
    ["John Power", "Jamie Walsh"]
  end
  
  def price
    DotNotationPrice.new
  end
  
  def availability
    { 'status' => true,
      'text' => 'In Stock' }
  end
  
  def truthy
    { 'zero' => 0,
      'non_true' => false }
  end
end

DotNotationView