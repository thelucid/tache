class ReturnTemplateView < Tache
  def single_line
    Tache::Template.new("<li>Single line: {{ok}}</li>\n")
  end
  
  def multi_line
    Tache::Template.new("<li>Multi: {{ok}}</li>\n<li>Line: {{ok}}</li>\n")
  end
  
  def ok
    'It works!'
  end
  
  def collection
    [
      { 'template' => Tache::Template.new("<li>First: {{ok}}</li>\n"), 'ok' => 'Yep' },
      { 'template' => Tache::Template.new("<li>Second: {{ok}}</li>\n") },
    ]
  end
end

ReturnTemplateView