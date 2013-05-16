require File.expand_path('../helper', __FILE__)

class ParserTest < Test::Unit::TestCase
  def setup
    @parser = Tache::Parser.new
  end
  
  test "can parse" do
    expectations = {
      ""                                        => [],
      "{{hi}}"                                  => [ ["line"], ["name", "hi", "", ""] ],
      "{{hi.world}}"                            => [ ["line"], ["name", "hi.world", "", ""] ],      
      "{{ hi}}"                                 => [ ["line"], ["name", "hi", "", ""] ],
      "{{hi }}"                                 => [ ["line"], ["name", "hi", "", ""] ],
      "{{ hi }}"                                => [ ["line"], ["name", "hi", "", ""] ],
      "{{{hi}}}"                                => [ ["line"], ["&", "hi", "", ""] ],
      "{{!hi}}"                                 => [ ["line"] ],
      "{{! hi}}"                                => [ ["line"] ],
      "{{! hi }}"                               => [ ["line"] ],
      "{{ !hi}}"                                => [ ["line"] ],
      "{{ ! hi}}"                               => [ ["line"] ],
      "{{ ! hi }}"                              => [ ["line"] ],
      "a\n b"                                   => [ ["line"], ["text", "a\n"], ["line"], ["text", " b" ] ],
      "a{{hi}}"                                 => [ ["line"], ["text", "a"], ["name", "hi", "", ""] ],
      "a {{hi}}"                                => [ ["line"], ["text", "a "], ["name", "hi", "", ""] ],
      " a{{hi}}"                                => [ ["line"], ["text", " a"], ["name", "hi", "", ""] ],
      " a {{hi}}"                               => [ ["line"], ["text", " a "], ["name", "hi", "", ""] ],
      "a{{hi}}b"                                => [ ["line"], ["text", "a"], ["name", "hi", "", ""], ["text", "b"] ],
      "a{{hi}} b"                               => [ ["line"], ["text", "a"], ["name", "hi", "", ""], ["text", " b"] ],
      "a{{hi}}b "                               => [ ["line"], ["text", "a"], ["name", "hi", "", ""], ["text", "b "] ],
      "a\n{{hi}} b \n"                          => [ ["line"], ["text", "a\n"], ["line"], ["name", "hi", "", ""], ["text", " b \n"] ],
      "a\n {{hi}} \nb"                          => [ ["line"], ["text", "a\n"], ["line"], ["name", "hi", " ", ""], ["text", " \n"], ["line"], ["text", "b"] ],
      "a\n {{!hi}} \nb"                         => [ ["line"], ["text", "a\n"], ["line"], ["text", " \n"], ["line"], ["text", "b"] ],
      "a\n{{#a}}{{/a}}\nb"                      => [ ["line"], ["text", "a\n"], ["line"], ["#", "a", [], "", ["{{", "}}"]], ["text", "\n"], ["line"], ["text", "b"] ],
      "a\n {{#a}}{{/a}}\nb"                     => [ ["line"], ["text", "a\n"], ["line"], ["text", " "], ["#", "a", [], "", ["{{", "}}"]], ["text", "\n"], ["line"], ["text", "b"] ],
      "a\n {{#a}}{{/a}} \nb"                    => [ ["line"], ["text", "a\n"], ["line"], ["text", " "], ["#", "a", [], "", ["{{", "}}"]], ["text", " \n"], ["line"], ["text", "b"] ],
      "a\n{{#a}}\n{{/a}}\nb"                    => [ ["line"], ["text", "a\n"], ["line"], ["#", "a", [["line"]], "", ["{{", "}}"]], ["line"], ["text", "b"] ],
      "a\n {{#a}}\n{{/a}}\nb"                   => [ ["line"], ["text", "a\n"], ["line"], ["#", "a", [["line"]], "", ["{{", "}}"]], ["line"], ["text", "b"] ],
      "a\n {{#a}}\n{{/a}} \nb"                  => [ ["line"], ["text", "a\n"], ["line"], ["#", "a", [["line"]], "", ["{{", "}}"]], ["text", " \n"], ["line"], ["text", "b"] ],
      "a\n{{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb"    => [ ["line"], ["text", "a\n"], ["line"], ["#", "a", [["line"]], "", ["{{", "}}"]], ["line"], ["#", "b", [["line"]], "", ["{{", "}}"]], ["line"], ["text", "b"] ],
      "a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb"   => [ ["line"], ["text", "a\n"], ["line"], ["#", "a", [["line"]], "", ["{{", "}}"]], ["line"], ["#", "b", [["line"]], "", ["{{", "}}"]], ["line"], ["text", "b"] ],
      "a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}} \nb"  => [ ["line"], ["text", "a\n"], ["line"], ["#", "a", [["line"]], "", ["{{", "}}"]], ["line"], ["#", "b", [["line"]], "", ["{{", "}}"]], ["text", " \n"], ["line"], ["text", "b"] ],
      "a\n{{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb"    => [ ["line"], ["text", "a\n"], ["line"], ["#",  "a",  [["line"], ["#", "b", [["line"]], "", ["{{", "}}"]], ["line"]], "{{#b}}\n{{/b}}\n",  ["{{", "}}"]], ["line"], ["text", "b"] ],
      "a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb"   => [ ["line"], ["text", "a\n"], ["line"], ["#",  "a",  [["line"], ["#", "b", [["line"]], "", ["{{", "}}"]], ["line"]],  "{{#b}}\n{{/b}}\n",  ["{{", "}}"]], ["line"], ["text", "b"] ],
      "a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}} \nb"  => [ ["line"], ["text", "a\n"], ["line"], ["#",  "a",  [["line"], ["#", "b", [["line"]], "", ["{{", "}}"]], ["line"]],  "{{#b}}\n{{/b}}\n",  ["{{", "}}"]], ["text", " \n"], ["line"], ["text", "b"] ],
      "{{>abc}}"                                => [ ["line"], [">", "abc", ""] ],
      "{{> abc }}"                              => [ ["line"], [">", "abc", ""] ],
      "{{ > abc }}"                             => [ ["line"], [">", "abc", ""] ],
      "{{=<% %>=}}"                             => [ ["line"] ],
      "{{= <% %> =}}"                           => [ ["line"] ],
      "{{=<% %>=}}<%={{ }}=%>"                  => [ ["line"] ],
      "{{=<% %>=}}<%hi%>"                       => [ ["line"], ["name", "hi", "", ""] ],
      "{{#a}}{{/a}}hi{{#b}}{{/b}}\n"            => [ ["line"], ["#", "a", [], "", ["{{", "}}"]], ["text", "hi"], ["#", "b", [], "", ["{{", "}}"]], ["text", "\n"] ],
      "{{a}}\n{{b}}\n\n{{#c}}\n{{/c}}\n"        => [ ["line"], ["name", "a", "", "\n"], ["line"], ["name", "b", "", "\n"], ["line"], ["text", "\n"], ["line"], ["#", "c", [["line"]], "", ["{{", "}}"]] ],
      "{{#foo}}\n  {{#a}}\n    {{b}}\n  {{/a}}\n{{/foo}}\n" => [["line"], ["#", "foo", [["line"], ["#", "a", [["line"], ["name", "b", "    ", "\n"], ["line"]], "    {{b}}\n    ", ["{{", "}}"]], ["line"]], "  {{#a}}\n    {{b}}\n  {{/a}}\n", ["{{", "}}"]]]
    }.each_with_index do |(template, tokens), index|
      assert_equal tokens, @parser.parse(template), "Item #{index} should match"
    end
  end
  
  test 'raises when there is an unclosed tag' do
    error = assert_raise(Tache::SyntaxError) { @parser.parse('My name is {{name') }
    assert_equal "Unclosed tag\n  Line 1:\n    My name is {{name\n                    ^", error.message
  end

  test 'raises when there is an unclosed section' do
    error = assert_raise(Tache::SyntaxError) { @parser.parse('A list: {{#people}}{{name}}') }
    assert_equal "Unclosed section 'people'\n  Line 1:\n    A list: {{#people}}{{name}}\n                    ^", error.message
  end

  test 'raises when closing unopened section' do
    error = assert_raise(Tache::SyntaxError) { @parser.parse('The end of the list! {{/people}}') }
    assert_equal "Closing unopened 'people'\n  Line 1:\n    The end of the list! {{/people}}\n                                 ^", error.message
  end

  test 'raises when invalid tags are given as an argument' do
    error = assert_raise(ArgumentError) { @parser.parse('A template <% name %>', ['<%']) }
    assert_equal "Invalid tags: '<%'", error.message
  end
  
  test 'raises when the template contains invalid tags' do
    error = assert_raise(Tache::SyntaxError) { @parser.parse('A template {{=<%=}}') }
    assert_equal "Invalid tags '<%'\n  Line 1:\n    A template {{=<%=}}\n                   ^", error.message
  end
end