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
      context = self
      segments = name.split('.')
      
      if segments.first == 'this'
        value = segments[1..-1].inject(context.view) do |view, key|
          break unless view
          resolve(view, key)
        end 
      else          
        while context
          value = segments.inject(context.view) do |view, key|
            break unless view
            resolve(view, key)
          end          

          break unless value == :missing
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
    view.is_a?(Tache) && view.partials[name] || parent.partial(name)
  end

  private
  
  # Could provide verbose mode that returns: "[missing: #{name}]"
  # ...or maybe pass to Tache instance like 'escape' and 'partal'.
  def missing(name)
    nil
  end
  
  def resolve(view, key)
    hash = view.respond_to?(:has_key?)
      
    scoped(view) do
      if hash && view.has_key?(key)
        view[key]
      elsif !hash && view.respond_to?(key)
        view.method(key).call
      else
        :missing
      end
    end
  end
  
  def scoped(view, &block)
    view.is_a?(Tache) ? view.scope(self, &block) : yield
  end
end