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
      type = token[0]
      token_value = token[1]
      
      case type
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
      when 'name', '&'
        value = context[token_value]
        value = if value.is_a?(Tache::Template)
          value.render(context, token[2])
        else
          value = value.is_a?(Proc) ? interpolate(value.call, context) : value.to_s
          value = token[2] + value + token[3]
          type == 'name' ? context.escape(value) : value
        end
        buffer << value if value
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