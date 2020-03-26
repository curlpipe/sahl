# Ruby compiler for sahl to html

=begin
Multiline tags
=end

class Parser
  attr_reader :multiline, :tag
  def initialize(sahl)
    # Load up the raw data and standardize
    @sahl = sahl
    @multiline = $mltable[@sahl]
    standardize
  end
  def standardize
    @tag = tag
    # Remove whitespace
    if (@sahl.include? @tag+" {")
      @sahl.sub!(@tag+" {", @tag+"{")
    end
    # Magic brackets
    if !@sahl.include? @tag+"{"
      @sahl.sub!(@tag+" ", @tag+"{")
      @sahl << "}"
    end
    return @sahl
  end
  def tag
    # Extract the tag type
    @sahl.match(/^(\w*)/).to_s
  end
  def contents
    # Extract the contents of the tag
    @sahl.match(/{(.*)}/).to_s[1...-1]
  end
  def export
    # Export to html
    @multiline ? @html = "<#{tag}>\n    #{contents}\n</#{tag}>" : @html = "<#{tag}>#{contents}</#{tag}>"
    @html.gsub!("!sahlbreak!", "\n    ")
    return @html
  end
  def validTag
    return true
  end
end

def read(file)
  $mltable = {}
  f = File.new(file, "r").readlines
  # Strip blank lines
  f.map!(&:strip).reject!{ |s| s.empty? }
  # Splice broken up tags
  result = []
  sub = []
  toggle = false
  f.each do |x|
    if (x.strip[-1] == "}" || x.strip == "}") && (!x.include?("{"))
      sub << x
      $mltable[x] = toggle
      toggle = false
      sub[-2].slice! "!sahlbreak!"
      result << sub.join
      $mltable[sub.join] = true
      sub = []
    elsif !x.include? "{"
      toggle ? sub << x+"!sahlbreak!" : result << x
      $mltable[x] = toggle
    elsif !x.include? "}"
      sub << x
      toggle = true
      $mltable[x] = toggle
    else
      toggle ? sub << x: result << x
      $mltable[x] = toggle
    end
  end
  return result
end

def write(toWrite)
  # Write resultant html to a file
  htmlName = ARGV[0][0...ARGV[0].length-5] + ".html"
  File.open(htmlName, "w") { |f| f.write(toWrite) }
end

def convert(input)
  output = ""
  # Convert a line of the file into html
  input.each do |line|
    parser = Parser.new(line)
    parser.validTag ? output << parser.export + "\n" : abort("ERROR: Inavlid tag: #{parser.tag}")
  end
  return output
end

# Take file argument
puts convert(read(ARGV[0]))
write(convert(read(ARGV[0])))
#p read(ARGV[0])
