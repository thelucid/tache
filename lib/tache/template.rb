class Tache::Template
  def initialize(source, options = {})
    @source = source
    @tags = options[:tags]
  end
  
  def render(context, indent = '')
    render_tokens(tokenize, context, indent)
  end
  
  def compile
    tokenize
    self
  end
  
  def compiled?
    !!@tokens
  end
  
  def to_str
    '[template]'
  end
  
  private
  
  def tokenize
    @tokens ||= Tache::Parser.new.parse(@source, @tags)
  end

  def render_tokens(tokens, context, indent = '')
    buffer = ''
    
    tokens.each do |token|
      type = token[0]
      content = token[1]
      
      case type
      when '#'
        value = context[content]
                
        if value == true
          buffer << render_tokens(token[2], context)
        elsif value.respond_to?(:call)
          buffer << interpolate(value.call(token[3]), context, token[4])
        elsif value.respond_to?(:has_key?) || !value.respond_to?(:each)
          unless falsy?(value)
            context.push(value) { |child| buffer << render_tokens(token[2], child) }
          end
        elsif value.respond_to?(:each)
          value.each do |item|
            context.push(item) { |child| buffer << render_tokens(token[2], child) }
          end
        end
      when '^'
        value = context[content]
        buffer << render_tokens(token[2], context) if falsy?(value)
      when '>'
        value = context.partial(content)
        buffer << value.render(context, token[2]) if value
      when 'name', '&'
        value = resolve(context, context[content], token[2], token[3], type == 'name')
        buffer << value if value
      when 'text'
        buffer << content
      when 'indent'
        buffer << indent
      end
    end

    buffer
  end
  
  def resolve(context, value, indent, newline, escape)    
    if value.is_a?(String)
      value = context.escape(value) if escape
      indent + value + newline
    elsif value.is_a?(Tache::Template)
      value.render(context, indent)
    elsif value.respond_to?(:each)
      return '' unless value.count > 0
      last = nil
      value = value.inject('') do |memo, item|
        context.push(item) do |child|
          memo << resolve(child, item, indent, '', escape)
        end
        indent = '' unless memo.end_with?("\n")
        last = item
        memo
      end
      last.is_a?(String) ? value << newline : value
    elsif value.respond_to?(:call)
      resolve(context, interpolate(value.call, context), indent, newline, escape)
    else
      stringish = value.to_s
      if stringish.is_a?(Tache::Template)
        context.push(value) { |child| stringish.render(child, indent) }
      else
        resolve(context, stringish, indent, newline, escape)
      end
    end
  end
  
  def interpolate(source, context, tags = nil)
    if source.is_a?(Tache::Template)
      source
    else
      Tache::Template.new(source.to_s, tags: tags)
    end.render(context.dup)
  end
  
  # Based on JavaScript implementation
  def falsy?(value)
    !value || value.respond_to?(:empty?) && value.empty? ||
              value.respond_to?(:zero?) && value.zero?
  end
end