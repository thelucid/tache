class HighOrderSectionsView < Tache
  def name
    "Tater"
  end
  
  def helper
    "To tinker?"
  end
  
  def bolder
    lambda do |text|
      text + ' => <b>' + render(text) + '</b> ' + helper
    end
  end
end

HighOrderSectionsView