# Ruby compiler for sahl to html

=begin
Multiline tags
=end

class Parser
  attr_reader :multiline
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
    @multiline ? @html = "<#{tag}>\n    " + contents + "\n</#{tag}>" : @html = "<#{tag}>" + contents + "</#{tag}>"
  end
end

def read(file)
  $mltable = {}
  f = File.new(file, "r").readlines
  # Strip blank lines
  f.map!(&:strip).reject!{ |s| s.empty? }
  # Strip newlines
  f.map! { |l| l.delete("\n") }
  # Splice broken up tags
  result = []
  sub = []
  toggle = false
  f.each do |x|
    if (x.strip[-1] == "}" || x.strip == "}") && (!x.include?("{"))
      sub << x
      $mltable[x] = toggle
      toggle = false
      result << sub.join
      $mltable[sub.join] = true
      sub = []
    elsif !x.include? "{"
      toggle ? sub << x : result << x
      $mltable[x] = toggle
    elsif !x.include? "}"
      sub << x
      toggle = true
      $mltable[x] = toggle
    else
      toggle ? sub << x : result << x
      $mltable[x] = toggle
    end
  end
  return result
end

def write
  # Write resultant html to a file
  htmlName = ARGV[0].split(".")[1..-1] + ".html"
  File.open(htmlName, "w") { |f| f.write("this feature aint workin yet boss") }
end

def convert(input)
  # Convert a line of the file into html
  input.each do |line|
    parser = Parser.new(line)
    puts parser.export
  end
end

# Take file argument
convert(read(ARGV[0]))
#p read(ARGV[0])
