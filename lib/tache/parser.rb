class Tache::Parser  
  def parse(source, tags = nil)
    return [] if source == ''
    
    tags ||= ['{{', '}}']
    raise ArgumentError, "Invalid tags: '#{tags.join(', ')}'" unless tags.size == 2
    
    state = :text
    index = 0
    start = 0
    finish = 0
    line = 0
    sections = []
    tokens = [['indent']]
    left = tags.first
    right = tags.last
    type = nil
    before = nil
    indent = ''
    standalone = nil    
    
    while char = source[index]
      case char
      # Note: left[0] and right[0] could be the same if tags have been changed,
      # hence the same when condition.
      when left[0], right[0]
        case state
        when :seek
          if char == '{'
            start = index + 1
            state = :pre
            type = '{'
          end
        when :text
          if source[index, left.size] == left
            if start == line && source[start...index] =~ /\A([\ \t]*)\Z/
              indent = $1
              standalone = true
            else
              tokens << ['text', source[start...index]] if index > start
              indent = ''
              standalone = false
            end
            
            before = index
            index += left.size - 1
            start = index + 1
            state = :seek
          end
        when :name, :special, :post
          if source[index, right.size] == right
            finish = index if state == :name || state == :special
            content = source[start...finish]
           
            # TODO: Probably a nicer way to handle tripples.
            if type == '{' && source[index, 1 + right.size] == ('}' + right)
              index += 1
              type = '&'
            end
            
            index += right.size - 1
              
            tail = ''
            if standalone
              carriage = source[index + 1] == "\r"
              index += 1 if carriage
              if source[index + 1] == "\n"
                index += 1
                line = index + 1
                tail = carriage ? "\r\n" : "\n"
              end
            end
             
            case type
            when 'name', '&'
              tokens << [type, content, indent, tail]
            when '#', '^'
              nested = []
              tokens << ['text', indent] if !indent.empty? && tail.empty?
              tokens << [type, content, nested]
              sections << [content, before, index + 1, tokens]
              tokens = nested
            when '/'
              tokens << ['text', indent] if !indent.empty? && tail.empty? && index + 1 != source.size
              name, at, pos, tokens = sections.pop
              error "Closing unopened '#{content}'", source, before unless name
              error "Unclosed section '#{name}'", source, at if name != content
              tokens.last << source[pos...before] + indent << tags
            when '>'
              tokens << ['>', content, indent]
            when '!'
            when '='
              if content[-1] == '='
                tags = content[0..-2].strip.split(' ')
                error "Invalid tags '#{tags.join(', ')}'", source, before unless tags.size == 2
                left, right = *tags
              end
            end
            
            start = index + 1
            state = :text
            tokens << ['indent'] unless tail.empty? || index + 1 == source.size
          end
        end
      when '#', '^', '/', '&', '>'
        case state
        when :seek
          start = index + 1
          state = :pre
          type = char
        end
      when '!', '='
        case state
        when :seek
          start = index + 1
          state = :special
          type = char
        end
      when '{'
        case state
        when :seek
          start = index + 1
          state = :pre
          type = '{'
        end
      when '}'
        case state
        when :name
          if type == '{'
            state = :post
            type = '&'
            finish = index
          end
        end
      when ' ', "\t"
        case state
        when :name
          state = :post
          finish = index
        end
      when /[\w\?!\/\.\-]/
        case state
        when :seek
          state = :name
          type = 'name'
          start = index
        when :pre
          state = :name
          start = index
        end
      when "\r"
      when "\n"
        case state
        when :text
          feed = (source[index - 1] == "\r" ? "\r\n" : "\n")
          tokens << ['text', source[start..index - feed.size] << feed]
          tokens << ['indent'] unless index + 1 == source.size
          start = index + 1
        end
        line = index + 1
      else
        case state
        when :seek, :pre, :name, :post
          # FIXME: This won't happen if character caught above.
          error "Invalid character in tag name: #{char.inspect}", source, index
        end
      end
      index += 1
    end
    
    unless sections.empty?
      name, at = sections.pop
      error "Unclosed section '#{name}'", source, at
    end
    
    case state
      when :text
        tokens << ['text', source[start...index]] if start < index
      when :name
        error "Unclosed tag", source, before
    end
    
    tokens
  end
  
  private

  def error(message, source, position)    
    rest = source[position..-1]
    size = rest.index("\n")
    rest = rest[0...size] if size
    lines = source[0...position].split("\n")
    row, column = lines.size, lines.last.size
    raise Tache::SyntaxError.new(message, row, column, lines.last + rest)
  end
end

class Tache::SyntaxError < StandardError
  def initialize(message, row, column, line)
    @message, @row, @column, @line = message, row, column, line
    @snippet = @line.strip
    @index = @column - (@line.size - @snippet.size)
  end

  def to_s
    "#{@message}\n  Line #{@row}:\n    #{@snippet}\n    #{' ' * @index}^"
  end
end