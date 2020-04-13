# The sahl converter
require 'optparse'

def index_all(hay, needle)
  array = []
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
      tag = "."+tag
      subtable = {}
      # Find all occurences of the tag
      o = index_all(@raw, tag)
      next if o.nil?
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
    table = table.max_by { |k, v| v[1] }
    return [grabTag(table[1][0]), table[1][1]]
  end
end

def standardise(raw)
  # Turn abstracted brackets into proper valid tags
  raw = raw.gsub("/*", "<!--").gsub("*/", "-->")
  result = []
  lines = raw.split("\n")
  lines.each do |line|
    if line.strip.start_with?("// ")
      line = "<!--#{line.strip[2..-1]} -->"
    elsif line.strip.start_with?("//")
      line = "<!-- #{line.strip[2..-1]} -->"
    elsif line.include?("// ")
      line = line.split("//", 2)
      line = line[0]+"<!--"+line[1]+" -->"
    elsif line.include?("//")
      line = line.split("//", 2)
      line = line[0]+"<!-- "+line[1]+" -->"
    end
    if line.strip.start_with?(".") && bracketBalance(line) == 0
      head = line.match(/(^\s*\.\w*(\[.*?\]|)\s*)/)[0].to_s
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
  data.chars.each do |ch|
    if ch == "{"
      trigger = true
      c += 1
    elsif ch == "}"
      c -= 1
    end
    line += ch
    if trigger && c == 0
      result.push line
      line = ""
      trigger = false
    end
  end
  return result
end

def convert(tag)
  # Where the conversion to HTML happens
  base = tag.clone
  tag.strip!
  type = tag.match(/^\s*\.(\w*)/m)[1].to_s
  contents = tag.match(/{(.*?)}\s*$/m)
  attributes = AttributeParser.new(tag)
  return "" if contents == nil
  contents = contents[-1].to_s
  if attributes.hasAttributes?
    return base.gsub(tag, "<#{type} #{attributes.html}>#{contents}</#{type}>")
  else
    return base.gsub(tag, "<#{type}>#{contents}</#{type}>")
  end
end

def convertBlock(block)
  # Recursively convert blocks
  print "." unless $silent
  p = Parser.new(block)
  loop do
    peak = p.getPeak[0]
    p.raw.gsub!(peak, convert(peak))
    p.updateTags
    break if p.tags.empty?
  end
  return p.raw
end

def convertRaw(data)
  # Take a file and convert it into html
  blocks = getBlocks(standardise(data))
  print "Parsing blocks: " unless $silent
  blocks.map! do |b|
    convertBlock(b) 
  end
  puts "\nWritten file to #{$out}" unless $silent
  return blocks.join
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
