class MyEnumerable
  include Enumerable

  def initialize
    @members = ['First', 'Second', 'Third']
  end

  def each(&block)
    @members.each(&block)
  end
end

class EnumerableView < Tache
  def items
    MyEnumerable.new
  end
end

EnumerableView