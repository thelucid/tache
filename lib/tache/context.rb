class Tache::Context
  attr_reader :view, :parent
  
  def initialize(view, parent = nil)
    @view, @parent = view, parent
    @cache = { '.' => view }
  end
  
  def push(view)
    yield @child = self.class.new(view, self)
  ensure
    @child = nil
  end
  
  def [](name)
    return @child[name] if @child

    @cache[name] ||= begin
      segments = name.split('.')
      
      if segments.first == 'this'
        value = fetch(self, segments[1..-1])
      else    
        context = self
        hit = false
        while context
          value = fetch(context, segments) do
            hit = true
          end

          break if hit
          context = context.parent
        end
      end
      
      value == :missing ? missing(name) : value
    end
  end

  def escape(str)
    view.is_a?(Tache) ? view.escape(str) : parent.escape(str)
  end

  def partial(name)
    view.is_a?(Tache) ? view.partials[name] : parent.partial(name)
  end

  private
  
  # Could log errors, maybe pass to Tache instance like 'escape' e.g.
  #   @errors << "Missing: #{name}"
  def missing(name)
    nil
  end
  
  def fetch(context, segments)
    segments.inject(context.view) do |view, key|
      break unless view
      resolved = resolve(view, key)
      yield if block_given? && resolved != :missing # && i == (segments.size - 1)
      resolved
    end
  end
  
  def resolve(view, key)
    hash = view.respond_to?(:has_key?)
      
    if hash && view.has_key?(key)
      view[key]
    elsif !hash && view.respond_to?(key)
      view.method(key).call
    else
      :missing
    end
  end
end