# A Few specs failing on whitespace issues, so commenting out for now.

require File.expand_path('../helper', __FILE__)
require 'tmpdir'
require 'yaml'

# Auto process !code types into procs.
# YAML::add_builtin_type('code') { |_, val| eval(val['ruby']) }

# Base class for each suite of specs.
class SpecTest < Test::Unit::TestCase
  def setup
    @tache = Class.new(Tache)
  end
end

(Dir[File.expand_path('../vendor/spec/specs/*.yml', __FILE__)] + Dir[File.expand_path('../fixtures/tests/*.json', __FILE__)]).each do |file|
  spec = YAML.load_file(file)

  klass_name = File.basename(file, File.extname(file)).sub(/~/, '').capitalize + 'Test'
  instance_eval "class ::#{klass_name} < SpecTest; end"
  test_suite = Kernel.const_get(klass_name)

  test_suite.class_eval do
    spec['tests'].each do |test|
      test test['name'].downcase do        
        # Manually doing it here as add_builtin_type doesn't seem to be working
        test['data']['lambda'] = eval(test['data']['lambda']['ruby']) if test['data'] && test['data']['lambda'] && test['data']['lambda']['ruby']
        
        args = [test['template'], test['data'], test['partials'] || {}]
        
        if test['expected_error']
          exception = assert_raise(Tache::SyntaxError) do
            @tache.render(*args)
          end
          assert_match /\A#{test['expected_error']}/, exception.message
        else                                                    
          assert_equal test['expected'], @tache.render(*args), "" <<
            "#{test['desc']}\n" <<
            "Data: #{test['data'].inspect }\n" <<
            "Template: #{test['template'].inspect}\n" <<
            "Partials: #{test['partials'] || {}.inspect}\n"
        end                                                     
      end
    end
  end
end