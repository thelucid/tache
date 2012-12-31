guard :test do
  watch(%r{^lib/(.+)\.rb$})                             { |m| "test/#{m[1]}_test.rb" }
  watch(%r{^lib/tache/(.+)\.rb$})                       { |m| "test/#{m[1]}_test.rb" }
  watch(%r{^test/.+_test\.rb$})
  watch('test/helper.rb')                               { "test" }
  watch(%r{^test/fixtures/.+\.(rb|json|txt|mustache)$}) { 'test/tache_test.rb' }
end
