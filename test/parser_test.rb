require File.expand_path('../helper', __FILE__)

class ParserTest < Test::Unit::TestCase
  def setup
    @parser = Tache::Parser.new
  end
  
  test "can parse" do
    expectations = {
      ""                                        => [],
      "{{hi}}"                                  => [ ["indent"], ["name", "hi", "", ""] ],
      "{{hi.world}}"                            => [ ["indent"], ["name", "hi.world", "", ""] ],      
      "{{ hi}}"                                 => [ ["indent"], ["name", "hi", "", ""] ],
      "{{hi }}"                                 => [ ["indent"], ["name", "hi", "", ""] ],
      "{{ hi }}"                                => [ ["indent"], ["name", "hi", "", ""] ],
      "{{{hi}}}"                                => [ ["indent"], ["&", "hi", "", ""] ],
      "{{!hi}}"                                 => [ ["indent"] ],
      "{{! hi}}"                                => [ ["indent"] ],
      "{{! hi }}"                               => [ ["indent"] ],
      "{{ !hi}}"                                => [ ["indent"] ],
      "{{ ! hi}}"                               => [ ["indent"] ],
      "{{ ! hi }}"                              => [ ["indent"] ],
      "a\n b"                                   => [ ["indent"], ["text", "a\n"], ["indent"], ["text", " b" ] ],
      "a{{hi}}"                                 => [ ["indent"], ["text", "a"], ["name", "hi", "", ""] ],
      "a {{hi}}"                                => [ ["indent"], ["text", "a "], ["name", "hi", "", ""] ],
      " a{{hi}}"                                => [ ["indent"], ["text", " a"], ["name", "hi", "", ""] ],
      " a {{hi}}"                               => [ ["indent"], ["text", " a "], ["name", "hi", "", ""] ],
      "a{{hi}}b"                                => [ ["indent"], ["text", "a"], ["name", "hi", "", ""], ["text", "b"] ],
      "a{{hi}} b"                               => [ ["indent"], ["text", "a"], ["name", "hi", "", ""], ["text", " b"] ],
      "a{{hi}}b "                               => [ ["indent"], ["text", "a"], ["name", "hi", "", ""], ["text", "b "] ],
      "a\n{{hi}} b \n"                          => [ ["indent"], ["text", "a\n"], ["indent"], ["name", "hi", "", ""], ["text", " b \n"] ],
      "a\n {{hi}} \nb"                          => [ ["indent"], ["text", "a\n"], ["indent"], ["name", "hi", " ", ""], ["text", " \n"], ["indent"], ["text", "b"] ],
      "a\n {{!hi}} \nb"                         => [ ["indent"], ["text", "a\n"], ["indent"], ["text", " \n"], ["indent"], ["text", "b"] ],
      "a\n{{#a}}{{/a}}\nb"                      => [ ["indent"], ["text", "a\n"], ["indent"], ["#", "a", [], "", ["{{", "}}"]], ["text", "\n"], ["indent"], ["text", "b"] ],
      "a\n {{#a}}{{/a}}\nb"                     => [ ["indent"], ["text", "a\n"], ["indent"], ["text", " "], ["#", "a", [], "", ["{{", "}}"]], ["text", "\n"], ["indent"], ["text", "b"] ],
      "a\n {{#a}}{{/a}} \nb"                    => [ ["indent"], ["text", "a\n"], ["indent"], ["text", " "], ["#", "a", [], "", ["{{", "}}"]], ["text", " \n"], ["indent"], ["text", "b"] ],
      "a\n{{#a}}\n{{/a}}\nb"                    => [ ["indent"], ["text", "a\n"], ["indent"], ["#", "a", [["indent"]], "", ["{{", "}}"]], ["indent"], ["text", "b"] ],
      "a\n {{#a}}\n{{/a}}\nb"                   => [ ["indent"], ["text", "a\n"], ["indent"], ["#", "a", [["indent"]], "", ["{{", "}}"]], ["indent"], ["text", "b"] ],
      "a\n {{#a}}\n{{/a}} \nb"                  => [ ["indent"], ["text", "a\n"], ["indent"], ["#", "a", [["indent"]], "", ["{{", "}}"]], ["text", " \n"], ["indent"], ["text", "b"] ],
      "a\n{{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb"    => [ ["indent"], ["text", "a\n"], ["indent"], ["#", "a", [["indent"]], "", ["{{", "}}"]], ["indent"], ["#", "b", [["indent"]], "", ["{{", "}}"]], ["indent"], ["text", "b"] ],
      "a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb"   => [ ["indent"], ["text", "a\n"], ["indent"], ["#", "a", [["indent"]], "", ["{{", "}}"]], ["indent"], ["#", "b", [["indent"]], "", ["{{", "}}"]], ["indent"], ["text", "b"] ],
      "a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}} \nb"  => [ ["indent"], ["text", "a\n"], ["indent"], ["#", "a", [["indent"]], "", ["{{", "}}"]], ["indent"], ["#", "b", [["indent"]], "", ["{{", "}}"]], ["text", " \n"], ["indent"], ["text", "b"] ],
      "a\n{{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb"    => [ ["indent"], ["text", "a\n"], ["indent"], ["#",  "a",  [["indent"], ["#", "b", [["indent"]], "", ["{{", "}}"]], ["indent"]], "{{#b}}\n{{/b}}\n",  ["{{", "}}"]], ["indent"], ["text", "b"] ],
      "a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb"   => [ ["indent"], ["text", "a\n"], ["indent"], ["#",  "a",  [["indent"], ["#", "b", [["indent"]], "", ["{{", "}}"]], ["indent"]],  "{{#b}}\n{{/b}}\n",  ["{{", "}}"]], ["indent"], ["text", "b"] ],
      "a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}} \nb"  => [ ["indent"], ["text", "a\n"], ["indent"], ["#",  "a",  [["indent"], ["#", "b", [["indent"]], "", ["{{", "}}"]], ["indent"]],  "{{#b}}\n{{/b}}\n",  ["{{", "}}"]], ["text", " \n"], ["indent"], ["text", "b"] ],
      "{{>abc}}"                                => [ ["indent"], [">", "abc", ""] ],
      "{{> abc }}"                              => [ ["indent"], [">", "abc", ""] ],
      "{{ > abc }}"                             => [ ["indent"], [">", "abc", ""] ],
      "{{=<% %>=}}"                             => [ ["indent"] ],
      "{{= <% %> =}}"                           => [ ["indent"] ],
      "{{=<% %>=}}<%={{ }}=%>"                  => [ ["indent"] ],
      "{{=<% %>=}}<%hi%>"                       => [ ["indent"], ["name", "hi", "", ""] ],
      "{{#a}}{{/a}}hi{{#b}}{{/b}}\n"            => [ ["indent"], ["#", "a", [], "", ["{{", "}}"]], ["text", "hi"], ["#", "b", [], "", ["{{", "}}"]], ["text", "\n"] ],
      "{{a}}\n{{b}}\n\n{{#c}}\n{{/c}}\n"        => [ ["indent"], ["name", "a", "", "\n"], ["indent"], ["name", "b", "", "\n"], ["indent"], ["text", "\n"], ["indent"], ["#", "c", [["indent"]], "", ["{{", "}}"]] ],
      "{{#foo}}\n  {{#a}}\n    {{b}}\n  {{/a}}\n{{/foo}}\n" => [["indent"], ["#", "foo", [["indent"], ["#", "a", [["indent"], ["name", "b", "    ", "\n"], ["indent"]], "    {{b}}\n    ", ["{{", "}}"]], ["indent"]], "  {{#a}}\n    {{b}}\n  {{/a}}\n", ["{{", "}}"]]],
      "{{< layout }}{{/ layout }}"              => [ ["indent"], ["<", "layout", []] ],
      "{{ < layout }}{{ / layout }}"            => [ ["indent"], ["<", "layout", []] ],
      "{{<layout}}{{/layout}}"                  => [ ["indent"], ["<", "layout", []] ],
      "{{$ block }}{{/ block }}"                => [ ["indent"], ["$", "block", []] ],
      "{{ $ block }}{{ / block }}"              => [ ["indent"], ["$", "block", []] ],
      "{{$block}}{{/block}}"                    => [ ["indent"], ["$", "block", []] ],
      "a\n{{<a}}\nb\n{{$b}}\nc\n{{/b}}\n{{/a}}\nd\n" =>
                                                   [ ["indent"], ["text", "a\n"], ["indent"], ["<", "a", [["indent"], ["text", "b\n"], ["indent"], ["$", "b", [["indent"], ["text", "c\n"], ["indent"]]], ["indent"]]], ["indent"], ["text", "d\n"] ]
    }.each_with_index do |(template, tokens), index|
      assert_equal tokens, @parser.parse(template), "Item #{index} should match:\n#{template.inspect}"
    end
  end
  
  test 'raises when there is an unclosed tag' do
    error = assert_raise(Tache::SyntaxError) { @parser.parse('My name is {{name') }
    assert_equal "Unclosed tag\n  Line 1:\n    My name is {{name\n               ^", error.message
  end

  test 'raises when there is an unclosed section' do
    error = assert_raise(Tache::SyntaxError) { @parser.parse('A list: {{#people}}{{name}}') }
    assert_equal "Unclosed section 'people'\n  Line 1:\n    A list: {{#people}}{{name}}\n            ^", error.message
  end

  test 'raises when closing unopened section' do
    error = assert_raise(Tache::SyntaxError) { @parser.parse('The end of the list! {{/people}}') }
    assert_equal "Closing unopened 'people'\n  Line 1:\n    The end of the list! {{/people}}\n                         ^", error.message
  end

  test 'raises when invalid tags are given as an argument' do
    error = assert_raise(ArgumentError) { @parser.parse('A template <% name %>', ['<%']) }
    assert_equal "Invalid tags: '<%'", error.message
  end
  
  test 'raises when the template contains invalid tags' do
    error = assert_raise(Tache::SyntaxError) { @parser.parse('A template {{=<%=}}') }
    assert_equal "Invalid tags '<%'\n  Line 1:\n    A template {{=<%=}}\n               ^", error.message
  end
end