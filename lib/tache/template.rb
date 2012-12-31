class Tache::Template
  def initialize(source, options = {})
    @source = source
    @options = options
  end
  
  def compile
    @tokens = Tache::Parser.new.parse(@source, @options[:tags])
    self
  end
  
  def render(context)
    compile unless @tokens
    render_tokens(@tokens, context)
  end
  
  def compiled?
    !!@tokens
  end
  
  private

  def render_tokens(tokens, context)
    buffer = ''
    
    tokens.each do |token|
      token_value = token[1]
      
      case token[0]
      when '#'
        value = context[token_value]
        
        case value
        when true
          buffer << render_tokens(token[4], context)
        when Proc
          buffer << interpolate(value.call(@source[token[3]..(token[5] - 1)]), context)  
        when Array, Enumerator
          value.each do |item|
            context.push(item) { |child| buffer << render_tokens(token[4], child) }
          end
        else
          context.push(value) do |child|
            buffer << render_tokens(token[4], child)
          end unless falsy?(value)
        end
      when '^'
        value = context[token_value]
        buffer << render_tokens(token[4], context) if falsy?(value)
      when '>'
        value = context.partial(token_value)
        buffer << value.render(context) if value
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
      end
    end
    
    buffer
  end
  
  def interpolate(source, context)
    self.class.new(source.to_s).render(context.dup)
  end
  
  # Based on JavaScript implementation
  def falsy?(value)
    !value || value.respond_to?(:empty?) && value.empty? ||
              value.respond_to?(:zero?) && value.zero?
  end
end