class Tache::Template
  def initialize(source, options = {})
    @source = source
    @tags = options[:tags]
  end
  
  def compile
    tokenize
    self
  end
  
  def render(context, indent = '')
    render_tokens(tokenize, context, indent)
  end
  
  def compiled?
    !!@tokens
  end
  
  private
  
  def tokenize
    @tokens ||= Tache::Parser.new.parse(@source, @tags)
  end

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
        value = resolve(context, context[token_value], token[2], token[3], type == 'name')
        buffer << value if value
      when 'text'
        buffer << token_value
      when 'line'
        buffer << indent
      end
    end

    buffer
  end
  
  def resolve(context, value, indent, newline, escape)
    value = value.to_tache_value if value.respond_to?(:to_tache_value)
    
    if value.is_a?(Tache::Template)
      value.render(context, indent)
    elsif value.is_a?(Array) || value.is_a?(Enumerator)
      last = value.last
      last = last.to_tache_value if last.respond_to?(:to_tache_value)
      after = last.is_a?(Tache::Template) ? '' : newline
      value.inject('') do |memo, item|
        context.push(item) { |child| memo << resolve(child, item, indent, '', escape) }
        indent = '' unless memo =~ /\n$/
        memo
      end << after
    else
      value = value.is_a?(Proc) ? interpolate(value.call, context) : value.to_s
      value = indent + value + newline
      escape ? context.escape(value) : value
    end
  end
  
  def interpolate(source, context, tags = nil)
    self.class.new(source.to_s, tags: tags).render(context.dup)
  end
  
  # Based on JavaScript implementation
  def falsy?(value)
    !value || value.respond_to?(:empty?) && value.empty? ||
              value.respond_to?(:zero?) && value.zero?
  end
end