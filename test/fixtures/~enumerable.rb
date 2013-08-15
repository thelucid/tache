class MyEnumerable
  include Enumerable

  def initialize
    @members = ['First', 'Second', 'Third']
  end

  def each(&block)
    @members.each(&block)
  end
  
  # FIXME: "last" isn't a requirement of Enumberable but using it blindly
  # within template.rb.
  def last
    @members.last
  end
end

class EnumerableView < Tache
  def items
    MyEnumerable.new
  end
end

EnumerableView