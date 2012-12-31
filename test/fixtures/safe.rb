require 'tache/safe'

class SafeView < Tache::Safe
  def thing
    'World'
  end
  
  def present
    "I'm here"
  end
  
  def bold
    lambda do |text|
      '<b>' + render(text) + '</b>'
    end
  end
end

SafeView