class NestedHighOrderSectionsView < Tache
  def bold
    lambda do |text|
      '<b>' + render(text) + '</b>'
    end
  end
  
  def person
    { 'name' => 'Jonas' }
  end
end

NestedHighOrderSectionsView