require 'strscan'
require 'cgi'

class Tache::Parser  
  WHITE       = /\s*/
  SPACE       = /\s+/
  TAG         = /#|\^|\/|>|\{|&|=|!/
  ALLOWED     = /(\w|[?!\/.-])*/
  SKIP_WHITE  = [ '#', '^', '/', '<', '>', '=', '!' ]
  ANY_CONTENT = ['!', '=']

  def parse(source = '', tags = nil)
    return [] if source == ''
    
    @encoding = source.encoding
    source = source.dup.force_encoding('BINARY')
    
    tags ||= ['{{', '}}']
    raise ArgumentError, "Invalid tags: '#{tags.join(', ')}'" unless tags.size == 2
    
    sections = []
    tokens = [['line']]
    @scanner = StringScanner.new(source)

    until @scanner.eos?
      open = /([ \t]*)?#{Regexp.escape(tags[0])}/
      close = /#{Regexp.escape(tags[1])}/
      text = scan_until_exclusive(open)

      unless text
        text = @scanner.rest
        @scanner.terminate
      end
      
      text.force_encoding(@encoding)
            
      text.lines.each do |line|
        tokens << ['text', line]
        tokens << ['line'] if line.end_with?("\n")
      end
      tokens.pop if tokens.last && tokens.last[0] == 'line' && @scanner.eos?

      start_of_line = @scanner.beginning_of_line?
      start = @scanner.pos
      last_index = tokens.length

      break unless @scanner.skip(open)
      space = @scanner[1] || ''

      unless start_of_line
        last = tokens.last
        (last && last[0] == 'text' ? last[1] += space : tokens << ['text', space]) unless space.empty?
        start += space.length
        space = ''
      end

      @scanner.skip(WHITE)
      type = @scanner.scan(TAG)
      @scanner.skip(WHITE)

      content = if ANY_CONTENT.include?(type)
        scan_until_exclusive(/#{WHITE}#{Regexp.escape(type)}?#{close}/)
      else
        @scanner.scan(ALLOWED)
      end

      error "Illegal content in tag" if content.empty?

      prev = tokens

      case type
      when '#', '^'
        block = []
        tokens << [type, content, block]
        sections << [content, @scanner.pos, tokens]
        tokens = block
      when '/'
        section, pos, result, last = sections.pop

        if section.nil?
          error "Closing unopened '#{content}'", @scanner.pos
        elsif section != content
          error "Unclosed section '#{section}'", pos
        end
        
        raw = @scanner.pre_match[last...start] + space
        tokens = result
        tokens.last << raw << tags
      when '='
        tags = content.split(' ')
        error "Invalid tags '#{tags.join(', ')}'", @scanner.pos unless tags.size == 2
      when '>'
        tokens << [type, content, space]
      when '{', '&'
        type = "}" if type == "{"
        tokens << ['&', content]
      when '!'
      else
        tokens << ['name', content]
      end

      @scanner.skip(SPACE)
      @scanner.skip(/#{Regexp.escape(type)}/) if type

      error "Unclosed tag", @scanner.pos unless @scanner.skip(close)

      if start_of_line && !@scanner.eos?
        if @scanner.peek(2) =~ /\r?\n/ && SKIP_WHITE.include?(type)
          @scanner.skip(/\r?\n/)
        else
          prev.insert(last_index, ['text', space]) unless space.empty?
        end
      end

      sections.last << @scanner.pos unless sections.empty?
    end

    unless sections.empty?
      type, pos = sections.pop
      error "Unclosed section '#{type}'", pos
    end

    tokens
  end

  private

  def scan_until_exclusive(regexp)
    pos = @scanner.pos
    return unless @scanner.scan_until(regexp)
    @scanner.pos -= @scanner.matched.size
    @scanner.pre_match[pos..-1]
  end

  def error(message, position)    
    rest = @scanner.string[position..-1]
    rest = rest[0...size] if size = rest.index("\n")
    lines = @scanner.string[0...position].split("\n")
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