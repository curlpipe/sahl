# The sahl converter
require 'optparse'
require 'json'
require 'pry'

$fw = "{\n   \"bulma\": \".meta[charset: \\\"utf-8\\\"]\\n.meta[name: \\\"viewport\\\", content: \\\"width=device-width, initial-scale=1\\\"]\\n.link[rel: \\\"stylesheet\\\", href: \\\"https://cdn.jsdelivr.net/npm/bulma@0.8.0/css/bulma.min.css\\\"]\",\n   \"bootstrap\": \".meta[charset: \\\"utf-8\\\"]\\n.meta[name: \\\"viewport\\\", content: \\\"width=device-width, initial-scale=1\\\"]\\n.link[href: \\\"https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css\\\", rel: \\\"stylesheet\\\"]\",\n   \"opensans\": \".link[href: \\\"https://fonts.googleapis.com/css?family=Open+Sans\\\", rel: \\\"stylesheet\\\", type: \\\"text/css\\\"]\",\n   \"fontawesome\": \".script[defer, src: \\\"https://use.fontawesome.com/releases/v5.3.1/js/all.js\\\"]\"\n}\n"
$fw = File.open("sahl.json", "r").read if File.file?("sahl.json")
$fw = JSON.parse($fw)

tagsFile = {"validTags"=>["!doctype", "a", "abbr", "acronym", "address", "applet", "area", "article", "aside", "audio", "b", "base", "basefont", "bb", "bdo", "big", "blockquote", "body", "br", "button", "canvas", "caption", "center", "cite", "code", "col", "colgroup", "command", "comment", "datagrid", "datalist", "dd", "del", "details", "dfn", "dialog", "dir", "div", "dl", "dt", "em", "embed", "eventsource", "fieldset", "figcaption", "figure", "font", "footer", "form", "frame", "frameset", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header", "hgroup", "hr", "html", "i", "iframe", "img", "input", "ins", "isindex", "kbd", "keygen", "label", "legend", "li", "link", "map", "mark", "menu", "meta", "meter", "nav", "noframes", "noscript", "object", "ol", "optgroup", "option", "output", "p", "param", "pre", "progress", "q", "rp", "rt", "ruby", "s", "samp", "script", "section", "select", "small", "source", "span", "strike", "strong", "style", "sub", "sup", "table", "tbody", "td", "textarea", "tfoot", "thead", "time", "title", "tr", "track", "tt", "u", "ul", "var", "video", "wbr"], 
            "voidTags"=>["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr", "command", "keygen", "menuitem"],
            "aloneTags"=>["script", "style"]}

$audit = []
$commentAudit = []
$validTags = tagsFile["validTags"]
$voidTags = tagsFile["voidTags"]
$aloneTags = tagsFile["aloneTags"]
$errorLog = []

class Array
  def squeeze(t)
    result = []
    each do |i|
      if i != t
        result.push i 
      elsif result[-1] != t
        result.push i
      end
    end
    return result
  end
end

def validTag?(tag)
  return $validTags.include? tag
end

def voidTag?(tag)
  return $voidTags.include? tag
end

def aloneTag?(tag)
  return $aloneTags.include? tag
end

def index_all(hay, needle)
  array = []
  inQuote = false
  (0..hay.length).each { |x| array.push hay.index(needle, x) }
  array = array.compact.uniq
end

class AttributeParser
  def initialize(block)
    @raw = block
    @at = @raw.match(/\.\w*\s*(|\[(.*?)\])\s*\{/)[-1].to_s
  end
  def hasAttributes?
    !@at.empty?
  end
  def html
    inQuotes = false
    result = ""
    seek = 0
    @at.chars.each do |ch|
      inQuotes = !inQuotes if ch == '"'
      if ch == ":" && !inQuotes
        result += "="
      elsif ch == "," && !inQuotes
      elsif ch == " " && !inQuotes && @at.chars[seek-1] == ":"
      else
        result += ch
      end
      seek += 1
    end
    return result
  end
end

class Parser
  attr_reader :tags
  attr_accessor :raw
  def initialize(block)
    # Obtain a list of tags
    @raw = block
    updateTags
  end
  def updateTags
    @tags = @raw.scan(/\s*\.(\w*)\s*(\{|\[)/).map!(&:first)
  end
  def grabTag(s)
    str = @raw[s..-1]
    controller = false
    c = 0
    contents = []
    str.chars.each do |b|
      if b == "{"
        controller = true
        c += 1
      elsif b == "}"
        c -= 1
      end
      contents.push(b)
      break if c == 0 unless !controller
    end
    return contents.join
  end
  def getPeak
    # Iterate through all tag types
    table = {}
    @tags.uniq.each do |tag|
      subtable = {}
      # Find all occurences of the tag
      o = index_all(@raw, /\.#{tag}\w*\W/)
      next if o.nil?
      tag = "."+tag
      # Find the highest
      highest = 0
      h = 0
      o.each do |i|
        level = bracketBalance(@raw[0..i])
        subtable[i] = level
      end
      table[tag] = subtable
    end
    table.each { |k, v| table[k] = v.max_by{ |k, v| v } }
    return [@raw, 0, 0] if table.values.compact.empty?
    table = table.compact.max_by { |k, v| v[1] } 
    return [grabTag(table[1][0]), table[1][1], table[1][0]]
  end
end

def comments(raw)
  raw = raw.gsub("/*", ".comment {").gsub("*/", "}")
  result = []
  lines = raw.split("\n")
  lines.each do |line|
    quotes = false
    if line.strip.start_with?("// ")
      line.sub!(line.strip, ".comment {#{line.strip[2..-1]} }")
    elsif line.strip.start_with?("//")
      line.sub!(line.strip, ".comment {#{line.strip[2..-1]}}")
    end
    line.chars.each_with_index do |ch, i|
      quotes = !quotes if ch == "\""
      begin
        if ch+line[i+1]+line[i+2] == "// " && !quotes
          line = line.split("//", 2)
          line = line[0]+"<!--"+line[1]+" -->"
        elsif ch+line[i+1] == "//" && !quotes
          line = line.split("//", 2)
          line = line[0]+"<!-- "+line[1]+" -->"
        end
      rescue; break; end
    end
    result.push line
  end
  return result.squeeze("").join("\n")
end

def templating(raw)
  result = []
  lines = raw.split("\n")
  lines.each do |line|
    if line.strip.start_with?("@")
      filename = line.strip[1..-1]
      w = line.match(/^(\s*)/)[0].to_s
      if $fw.include?(filename)
        f = standardise($fw[filename]).split("\n")
        f.map! { |l| w+l.strip }
        f = f.join("\n").strip
      elsif filename.end_with?(".sahl")
        f = standardise(File.open(filename, "r").read)
      end
      if filename.end_with?(".sahl")
        f = convertRaw(f).split("\n")
        f.map! { |l| w+l }
        f = f[1..-1].join("\n")
      elsif filename.end_with?(".css")
        f = w+".link[rel:\"stylesheet\", type:\"text/css\", href:\"#{filename}\"]{}"
      elsif filename.end_with?(".js")
        f = w+".script[type:\"text/javascript\", src:\"#{filename}\"]{}"
      else
        f = w+f
      end
      line = f
    end
    result.push line
  end
  return result.join("\n")
end

def standardise(raw)
  # Turn abstracted brackets into proper valid tags
  brackets = raw.scan(/\[(.*?)\]/m).compact
  if !brackets.empty?
    brackets.each { |m| raw.gsub!(m[0], m[0].delete("\n").squeeze(" ")) }
  end
  result = []
  lines = raw.split("\n")
  lines.each do |line|
    if line.strip.start_with?(".") && bracketBalance(line) == 0
      head = line.match(/(^\s*\.\w*\s*(\[.*?\]|)\s*)/)[0].to_s
      contents = line.sub(head, "")
      hasBrackets = contents[0] == "{" && contents[-1] == "}"
      contents = "{#{contents}}" if !hasBrackets
      result.push "\n"+head+contents
    else
      result.push "\n"+line
    end
  end
  return result.join
end

def bracketBalance(data)
  # Return the net balance of the brackets
  c = 0
  data.chars.each do |b|
    if b == "{"
      c += 1
    elsif b == "}"
      c -= 1
    end
  end
  return c
end

def getBlocks(data)
  # Seperate everything by matching brackets
  result = []
  c = 0
  line = ""
  trigger = false
  comment = false
  data = data.chars
  loop do 
    ch = data.shift
    if ch == "{"
      trigger = true
      c += 1
    elsif ch == "}"
      c -= 1
    elsif ch+data[0] == "/*"
      comment = true
    elsif ch+data[0] == "*/"
      comment = false
      ch += data.shift
    end
    line += ch
    if trigger && c == 0 && !comment
      result.push line
      line = ""
      trigger = false
    end
    break if data.empty?
  end
  return result
end

def convertFirst(tag)
  # Convert only the outermost tag
  type = tag.match(/^\s*\.(\w*)/m)[1].to_s
  contents = tag.match(/\.#{type}(|\s*\[.*?\])\s*\{(.*)\}$/m)
  return "<#{type}>#{contents[-1]}</#{type}>" if contents[1].empty?
  return "<#{type} #{AttributeParser.new(tag).html}>#{contents[-1]}</#{type}>"
end

def convert(tag)
  # Where the conversion to HTML happens
  base = tag.clone
  tag.strip!
  type = tag.match(/^\s*\.(\w*)/m)
  return base if type.nil?
  type = type[1].to_s
  contents = tag.match(/{(.*?)}\s*$/m)
  return "" if contents == nil
  contents = contents[-1].to_s
  attributes = AttributeParser.new(tag)
  if !$silent
    if validTag? type
      print "."
    else
      print "!"
      $errorLog.push "Warning: Invalid tag '#{type}' detected"
    end
  end
  if voidTag? type
    if attributes.hasAttributes?
      return base.gsub(tag, "<#{type} #{attributes.html}>")
    else
      return base.gsub(tag, "<#{type}>")
    end
  else
    if attributes.hasAttributes?
      return base.gsub(tag, "<#{type} #{attributes.html}>#{contents}</#{type}>")
    else
      return base.gsub(tag, "<#{type}>#{contents}</#{type}>")
    end
  end
end

def convertBlock(block)
  # Recursively convert blocks
  p = Parser.new(block)
  # Set up audits before conversion
  if $aloneTags.map { |t| p.tags.include?(t) }.any?
    i = []
    $aloneTags.each { |t| i.push(p.raw.index("."+t)) }
    tag = p.grabTag(i.compact.max)
    type = tag.match(/^\s*\.(\w*)/m)[1].to_s
    $audit.push tag
    p.raw.sub!(tag, "&"+$audit.length.to_s)
  end
  p.raw = templating(p.raw)
  p.updateTags
  p.raw = comments(p.raw)
  p.updateTags
  if p.tags.include?("comment")
    tag = p.grabTag(p.raw.index(".comment"))
    type = tag.match(/^\s*\.(\w*)/m)[1].to_s
    $commentAudit.push tag
    p.raw.sub!(tag, "$"+$commentAudit.length.to_s)
  end
  loop do
    peak = p.getPeak[0]
    p.raw.gsub!(peak, convert(peak))
    p.updateTags
    break if p.tags.empty?
  end
  # Reapply audits after conversion
  $audit.each_with_index { |a, i| p.raw.sub!("&"+(i+1).to_s, convertFirst(a)) }
  $commentAudit.each_with_index { |a, i| p.raw.sub!("$"+(i+1).to_s, convertFirst(a)) }
  p.raw.gsub!("<comment>", "<!--")
  p.raw.gsub!("</comment>", "-->")
  return p.raw
end

def convertRaw(data)
  # Take a file and convert it into html
  blocks = getBlocks(standardise(data))
  print "Parsing: " unless $silent
  blocks.map! { |b| "\n"+convertBlock(b) }
  puts "\nWritten file to #{$out}" unless $silent
  blocks = blocks.join
  blocks = "\n"+blocks if !blocks.start_with?("\n")
  return "<!DOCTYPE html>"+blocks
end

$silent = false
$in = ARGV[-1]
$out = $in.sub(/(\.\w*)$/, ".html")
OptionParser.new do |opts|
  opts.banner = "Usage: sahl [options] [input]"
  opts.on("-s", "--silent", "Stop all output to stdout") { |s| $silent = s }
  opts.on("-oFILENAME", "--output filename", "File to write to") { |o| $out = o }
end.parse!
f = File.open($in, "r").read
w = File.open($out, "w")
w.seek 0
w.write convertRaw(f)
puts $errorLog
