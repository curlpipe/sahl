require_relative 'parser.rb'
require_relative 'read.rb'
require 'json'

tagsFile = JSON.parse(File.open("../assets/validTags.json").read)
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
    nl = convert(peak[1], attr = AttributeParser.new(peak[1]))
    type = peak[1].match(/^\.(\w*)/).to_s[1..-1]
    parser.tags.chuck type
    parser.string.gsub!(peak[1], nl)
    break if peak[0] == 0
  end
  parser.string.gsub!("!sahlbreak!", "\n")
  parser.string.gsub!("!sahlspace!", "  ")
  return parser.string
end

def doWork
  $silent = ARGV.length > 1 && ARGV[-1] == "-s"
  file = "#{Dir.pwd}/#{ARGV[0]}"
  data = read(file)

  result = []
  print "Parsing blocks: " unless $silent
  data.each do |line|
    result.push convertLine(line)
  end
  puts "\n\n" unless $silent
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
