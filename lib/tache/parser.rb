require 'strscan'
require 'cgi'

class Tache::Parser  
  WHITE       = /\s*/
  TAG         = /#|\^|\/|>|\{|&|=|!/
  NON_INLINE  = /#|\^|\/|>|=|!/
  ANY_CONTENT = /!|=/
  ALLOWED     = /(\w|[\?!\/\.\-])*/

  def parse(source = '', tags = nil)
    return [] if source == ''
    tags ||= ['{{', '}}']
    raise ArgumentError, "Invalid tags: '#{tags.join(', ')}'" unless tags.size == 2
    
    encoding = source.encoding
    source = source.dup.force_encoding('BINARY')    
    sections = []
    tokens = [['line']]
    scanner = StringScanner.new(source)

    until scanner.eos?
      open = /([ \t]*)?#{Regexp.escape(tags[0])}/
      close = /#{Regexp.escape(tags[1])}/
      text = scanner.scan_until(open)

      if text
        size = scanner.matched.size
        text = text[0...-size]
        scanner.pos -= size
      else
        text = scanner.rest
        scanner.terminate
      end
      
      text.force_encoding(encoding)
            
      text.lines.each do |line|
        tokens << ['text', line]
        tokens << ['line'] if line.end_with?("\n")
      end
      tokens.pop if tokens.last && tokens.last[0] == 'line' && scanner.eos?

      newline = scanner.bol?
      start = scanner.pos
      
      break unless scanner.skip(open)
      
      indent = scanner[1] || ''

      unless newline || indent.empty?
        last = tokens.last
        last && last[0] == 'text' ? last[1] << indent : tokens << ['text', indent]
        start += indent.length
        indent = ''
      end

      scanner.skip(WHITE)
      type = scanner.scan(TAG)
      scanner.skip(WHITE)

      content = if ANY_CONTENT =~ type
        text = scanner.scan_until(/#{WHITE}#{Regexp.escape(type)}?#{close}/)
        size = scanner.matched.size
        scanner.pos -= size
        text[0...-size]
      else
        scanner.scan(ALLOWED)
      end

      scanner.skip(WHITE)
      scanner.skip(/\}/) if type == '{'
      scanner.skip(/\=/) if type == '='

      error "Unclosed tag", source, scanner.pos unless scanner.skip(close)

      tail = ''
      if newline && scanner.peek(2) =~ /\r?\n/
        tail = scanner.scan(/\r?\n/) || ''
      elsif !scanner.eos? && !indent.empty? && NON_INLINE =~ type
        last = tokens.last
        last && last[0] == 'text' ? last[1] << indent : tokens << ['text', indent]
      end
      
      case type
      when '#', '^'
        nested = []
        tokens << [type, content, nested]
        sections << [content, scanner.pos, tokens]
        tokens = nested
      when '/'
        name, pos, tokens, last = sections.pop
        error "Closing unopened '#{content}'", source, scanner.pos - 2 if name.nil?
        error "Unclosed section '#{name}'", source, pos if name != content
        tokens.last << (source[last...(start + indent.length)] + indent) << tags
      when '='
        tags = content.split(' ')
        error "Invalid tags '#{tags.join(', ')}'", source, scanner.pos - 3 unless tags.size == 2
      when '>'
        tokens << [type, content, indent]
      when '!'
        # Ignore
      when '{', '&'
        tokens << ['&', content, indent, tail]
      else
        tokens << ['name', content, indent, tail]
      end
      
      tokens << ['line'] unless tail.empty? || scanner.eos?
      sections.last << scanner.pos unless sections.empty?
    end

    unless sections.empty?
      name, pos = sections.pop
      error "Unclosed section '#{name}'", source, pos - 2
    end

    tokens
  end

  private

  def error(message, source, position)    
    rest = source[position..-1]
    size = rest.index("\n")
    rest = rest[0...size] if size
    lines = source[0...position].split("\n")
    row, column = lines.size, lines.last.size - 1
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