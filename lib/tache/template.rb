class Tache::Template
  def initialize(source, options = {})
    @source = source
    @tags = options[:tags]
  end
  
  def compile
    @tokens = Tache::Parser.new.parse(@source, @tags)
    self
  end
  
  def render(context, indent = '')
    compile unless @tokens
    render_tokens(@tokens, context, indent)
  end
  
  def compiled?
    !!@tokens
  end
  
  private

  def render_tokens(tokens, context, indent = '')
    buffer = ''
    
    tokens.each do |token|
      token_value = token[1]
      
      case token[0]
      when '#'
        value = context[token_value]
        
        case value
        when true
          buffer << render_tokens(token[2], context)
        when Proc
          buffer << interpolate(value.call(token[3]), context, token[4])  
        when Array, Enumerator
          value.each do |item|
            context.push(item) { |child| buffer << render_tokens(token[2], child) }
          end
        else
          context.push(value) do |child|
            buffer << render_tokens(token[2], child)
          end unless falsy?(value)
        end
      when '^'
        value = context[token_value]
        buffer << render_tokens(token[2], context) if falsy?(value)
      when '>'
        value = context.partial(token_value)
        buffer << value.render(context, token[2]) if value
      when '&'
        value = context[token_value]
        value = interpolate(value.call, context) if value.is_a?(Proc)
        buffer << value.to_s unless value.nil?
      when 'name'
        value = context[token_value]
        value = interpolate(value.call, context) if value.is_a?(Proc)
        buffer << context.escape(value.to_s) unless value.nil?
      when 'text'
        buffer << token_value
      when 'line'
        buffer << indent
      end
    end

    buffer
  end
  
  def interpolate(source, context, tags = nil)
    self.class.new(source.to_s, :tags => tags).render(context.dup)
  end
  
  # Based on JavaScript implementation
  def falsy?(value)
    !value || value.respond_to?(:empty?) && value.empty? ||
              value.respond_to?(:zero?) && value.zero?
  end
end