require 'strscan'
require 'cgi'

class Tache::Parser  
  WHITE     = /\s*/
  SPACE     = /\s+/
  NON_SPACE = /\S/
  EQ        = /\s*=/
  CURLY     = /\s*\}/
  TAG       = /#|\^|\/|>|\{|&|=|!/

  def initialize
    @tags = ['{{', '}}']
  end
    
  def parse(source = '', tags = nil)
    if source.respond_to?(:encoding)
      @encoding = source.encoding
      source = source.dup.force_encoding("BINARY")
    else
      @encoding = nil
    end
    
    tags ||= @tags
    raise ArgumentError, "Invalid tags: '#{tags.join(', ')}'" unless tags.size == 2

    tag_res = escape_tags(tags)      
    scanner = StringScanner.new(source)

    sections, tokens, spaces = [], [], []
    has_tag, non_space = false

    strip_space = proc do
      if has_tag && !non_space
        tokens.delete_at(spaces.pop) while !spaces.empty?
      else
        spaces = []
      end
      has_tag, non_space = false
    end

    while !scanner.eos?
      start = scanner.pos
      value = scan_up_to(scanner, tag_res[0])

      value.each_char do |chr|            
        chr !~ NON_SPACE ? spaces << tokens.size : non_space = true
        chr.force_encoding(@encoding) if @encoding
        tokens << ['text', chr, start, start + 1]
        start += 1;
        strip_space.call if chr == "\n"
      end

      break unless scanner.scan(tag_res[0])
      has_tag = true
      type = scanner.scan(TAG) || 'name'           
      scanner.scan(WHITE)

      case type
      when '='
        value = scan_up_to(scanner, EQ)
        scanner.scan(EQ)
        scan_up_to(scanner, tag_res[1])
      when '{'
        exp = Regexp.new('\s*' + Regexp.escape('}' + tags[1]))
        value = scan_up_to(scanner, exp)
        scanner.scan(CURLY)
        scan_up_to(scanner, tag_res[1])
        type = '&'
      else
        value = scan_up_to(scanner, tag_res[1])
      end

      error 'Unclosed tag', scanner.pos unless scanner.scan(tag_res[1])
      token = [type, value, start, scanner.pos]
      tokens << token

      case type
      when '#', '^'
        sections << token
      when '/'
        error "Unopened section '#{value}'", start if sections.empty?
        section = sections.pop
        error "Unclosed section '#{section[1]}'", start if section[1] != value
      when 'name', '{', '&'
        non_space = true
      when '='
        tags = value.split(SPACE)
        error "Invalid tags '#{tags.join(', ')}'", start unless tags.size == 2
        tag_res = escape_tags(tags)
      end
    end

    open_section = sections.pop
    error "Unclosed section '#{open_section[1]}'", scanner.pos if open_section

    nest_tokens(squash_tokens(tokens))
  end

  private

  def scan_up_to(scanner, regexp)
    pos = scanner.pos
    if scanner.scan_until(regexp)
      scanner.pos -= scanner.matched.size
      scanner.pre_match[pos..-1]
    else
      scanner.rest
    end
  end

  def nest_tokens(tokens)
    tree = collector = []
    sections = []

    tokens.each do |token|
      case token[0]
      when '#', '^'
        sections << token
        collector << token
        collector = token[4] = []
      when '/'
        section = sections.pop
        section[5] = token[2]
        collector = sections.empty? ? tree : sections.last[4]
      else
        collector << token
      end
    end

    tree
  end

  def squash_tokens(tokens)
    squashed = []
    last = nil

    tokens.each do |token|
      if token[0] == 'text' && last && last[0] == 'text'
        last[1] += token[1]
        last[3] = token[3]
      else
        last = token
        squashed << token
      end
    end
    squashed
  end

  def escape_tags(tags)
    [/#{Regexp.escape(tags[0])}\s*/, /\s*#{Regexp.escape(tags[1])}/]
  end

  def error(message, position)
    raise Tache::SyntaxError.new(message, position)
  end
end

class Tache::SyntaxError < StandardError
  def initialize(message, position)
    @message = message
    @position = position
  end

  def to_s
    "#{@message} at: #{@position}"
  end
end