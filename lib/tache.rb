if defined?(Motion::Project::Config)
  Motion::Project::App.setup do |app|
    base = File.expand_path('../tache', __FILE__)
    Dir.glob("#{base}/*.rb").each do |file|
      app.files.unshift(file)
    end
    app.files_dependencies "#{base}/parser.rb" => "#{base}/strscan.rb"
    app.files_dependencies "#{base}/safe.rb" => "#{base}/context.rb"
    app.files_dependencies "#{base}/tache.rb" => "#{base}/context.rb"
  end
else
  # Parser requirements
  require 'strscan'
  require 'cgi'
  
  # Tache
  require 'tache/version'
  require 'tache/context'
  require 'tache/parser'
  require 'tache/template'
  require 'tache/tache'
end