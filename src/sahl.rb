require_relative 'parser.rb'
require_relative 'read.rb'

tagsFile = {"validTags"=>["!doctype", "a", "abbr", "acronym", "address", "applet", "area", "article", "aside", "audio", "b", "base", "basefont", "bb", "bdo", "big", "blockquote", "body", "br", "button", "canvas", "caption", "center", "cite", "code", "col", "colgroup", "command", "datagrid", "datalist", "dd", "del", "details", "dfn", "dialog", "dir", "div", "dl", "dt", "em", "embed", "eventsource", "fieldset", "figcaption", "figure", "font", "footer", "form", "frame", "frameset", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header", "hgroup", "hr", "html", "i", "iframe", "img", "input", "ins", "isindex", "kbd", "keygen", "label", "legend", "li", "link", "map", "mark", "menu", "meta", "meter", "nav", "noframes", "noscript", "object", "ol", "optgroup", "option", "output", "p", "param", "pre", "progress", "q", "rp", "rt", "ruby", "s", "samp", "script", "section", "select", "small", "source", "span", "strike", "strong", "style", "sub", "sup", "table", "tbody", "td", "textarea", "tfoot", "thead", "time", "title", "tr", "track", "tt", "u", "ul", "var", "video", "wbr", "comment"], 
            "voidTags"=>["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr", "command", "keygen", "menuitem"]}

$validTags = tagsFile["validTags"]
$voidTags = tagsFile["voidTags"]
$errorLog = []

class Array
  def chuck(x)
    delete_at(index(x))
  end
end

def isBlank?(x)
  x.strip == ""
end

def validTag?(tag)
  return $validTags.include? tag
end

def voidTag?(tag)
  return $voidTags.include? tag
end

def convert(tag, attr = nil)
  type = tag.match(/^\.(\w*)/).to_s[1..-1]
  contents = tag.match(/{(.*)}\s*$/)
  return "" if contents == nil
  contents = contents[1].to_s.strip
  if !$silent
    if validTag?(type)
      print "."
    else
      print "!"
      $errorLog.push "Warning: Invalid tag '#{type}' detected"
    end
  end
  if !voidTag?(type)
    return "<#{type}>#{contents}</#{type}>" if attr == nil || attr.raw == ""
    return "<#{type} #{attr.html}>#{contents}</#{type}>"
  else
    return "<#{type}>" if attr == nil || attr.raw == ""
    return "<#{type} #{attr.html}>"
  end
end

def convertLine(line)
  return "" if isBlank? line
  line = absFilter(line)
  parser = Parser.new(line)
  loop do
    peak = parser.getPeak
    break if Parser.new(peak[1]).tags.empty?
    nl = convert(peak[1], attr = AttributeParser.new(peak[1]))
    type = peak[1].match(/^\.(\w*)/).to_s[1..-1]
    parser.tags.chuck type
    parser.string.gsub!(peak[1], nl)
  end
  parser.string.gsub!("<comment>", "<!-- ")
  parser.string.gsub!("</comment>", " -->")
  parser.string.gsub!("!sahlbreak!", "\n")
  parser.string.gsub!("!sahlspace!", "  ")
  return parser.string
end

def doWork
  $silent = ARGV.length > 1 && ARGV[-1] == "-s"
  file = "#{Dir.pwd}/#{ARGV[0]}"
  data = read(file)

  result = ["<!DOCTYPE html>"]
  print "Parsing blocks: " unless $silent
  data.each do |line|
    result.push convertLine(line)
  end
  puts "\n\n" unless $silent || $errorLog.empty?
  $errorLog.each do |error|
    puts error
  end

  new = file.sub(/(\.\w*)$/, ".html")
  f = File.open(new, "w")
  f.seek(0)
  f.write(result.join "\n")
  puts "\nWritten to #{new}" unless $silent
end

doWork if __FILE__ == $0
