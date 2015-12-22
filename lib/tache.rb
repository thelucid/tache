base = File.expand_path('../tache', __FILE__)

if defined?(Motion::Project::Config)
  Motion::Project::App.setup do |app|
    Dir.glob("#{base}/*.rb").each do |file|
      app.files.unshift(file)
    end
    app.files_dependencies "#{base}/safe.rb" => "#{base}/context.rb"
    app.files_dependencies "#{base}/tache.rb" => "#{base}/context.rb"
  end
else
  # Tache
  require "#{base}/version"
  require "#{base}/context"
  require "#{base}/parser"
  require "#{base}/template"
  require "#{base}/tache"
end