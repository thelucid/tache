require File.expand_path('../helper', __FILE__)

class ContextTest < Test::Unit::TestCase
  def setup
    @parent = Tache::Context.new({ 'name' => 'parent', 'message' => 'hi', 'a' => { 'b' => 'b' } })
    @child_view = { 'name' => 'child', 'c' => { 'd' => 'd' } }
  end
  
  test 'is able to lookup properties of its own view' do
    assert_equal @parent['name'], 'parent'
  end

  test 'is able to lookup nested properties of its own view' do
    assert_equal @parent['a.b'], 'b'
  end

  test 'push returns the child context' do
    @parent.push(@child_view) do |child|
      assert_equal 'child', child.view['name']
      assert_equal 'parent', child.parent.view['name']
    end
  end

  test 'child can lookup properties of own view' do
    @parent.push(@child_view) do |child|
      assert_equal 'child', child['name']
    end
  end

  test 'child can lookup properties of the parent context view' do
    @parent.push(@child_view) do |child|
      assert_equal 'hi', child['message']
    end
  end

  test 'child can lookup nested properties of own view' do
    @parent.push(@child_view) do |child|
      assert_equal 'd', child['c.d']
    end
  end

  test "child can lookup nested properties of parent view" do
    @parent.push(@child_view) do |child|
      assert_equal 'b', child['a.b']
    end
  end
end