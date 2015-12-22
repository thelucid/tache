class Tache::Parser
  ALLOWED = /[\w\?!\/\.\-]/
  
  def parse(source, tags = nil)
    return [] if source == ''
    
    tags ||= ['{{', '}}']
    raise ArgumentError, "Invalid tags: '#{tags.join(', ')}'" unless tags.size == 2
    
    state = :text
    index = 0
    start = 0
    finish = 0
    line = 0
    tokens = [['indent']]
    sections = []
    layout = false
    left = tags.first
    right = tags.last
    type = nil
    before = nil
    indent = ''
    standalone = nil
    
    while char = source[index]
      case state
      when :text
        case char
        when left[0]
          if source[index, left.size] == left
            # TODO: Handle indents better.
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
        when "\r"
        when "\n"
          feed = (source[index - 1] == "\r" ? "\r\n" : "\n")
          tokens << ['text', source[start..index - feed.size] << feed]
          tokens << ['indent'] unless index + 1 == source.size
          start = index + 1
          line = index + 1
        end
      when :seek
        case char
        when '#', '^', '/', '&', '>', '{', '<', '$'
          start = index + 1
          state = :pre
          type = char
        when '!', '='
          start = index + 1
          state = :special
          type = char
        when ALLOWED
          state = :name
          type = 'name'
          start = index
        end
      when :pre
        case char
        when ALLOWED
          state = :name
          start = index
        when ' '
          # Valid space.
        else
          error "Invalid character in tag name: #{char.inspect}", source, index
        end
      when :name, :special, :post
        case char
        when right[0]
          if source[index, right.size] == right
            content = source[start...(state == :post ? finish : index)]

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
              error "Illegal tag inside a partial override tag", source, before if layout
              tokens << [type, content, indent, tail]
            when '#', '^', '<', '$'
              if layout && type != '$'
                error "Illegal tag inside a partial override tag", source, before
              end
              nested = []
              tokens << ['text', indent] if !indent.empty? && tail.empty?
              tokens << [type, content, nested]
              sections << [content, before, index + 1, tokens]
              tokens = nested
              layout = (type == '<')
            when '>'
              error "Illegal tag inside a partial override tag", source, before if layout
              tokens << ['>', content, indent]
            when '!'
            when '='
              if content[-1] == '='
                tags = content[0..-2].strip.split(' ')
                error "Invalid tags '#{tags.join(', ')}'", source, before unless tags.size == 2
                left, right = *tags
              end
            when '/'
              tokens << ['text', indent] if !indent.empty? && tail.empty? && index + 1 != source.size
              name, at, pos, tokens = sections.pop
              error "Closing unopened '#{content}'", source, before unless name
              error "Unclosed section '#{name}'", source, at if name != content
              tokens.last << source[pos...before] + indent << tags if tokens.last[0] == '#'
              layout = (tokens.last[0] == '$')
            end
    
            start = index + 1
            state = :text
            tokens << ['indent'] unless tail.empty? || index + 1 == source.size
          end
        when ALLOWED
          # Valid char.
        when '}'
          if type == '{'
            state = :post
            type = '&'
            finish = index
          end
        when ' ', "\t"
          if state == :name
            state = :post
            finish = index
          end
        else
          unless state == :special
            error "Invalid character in tag name: #{char.inspect}", source, index
          end
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