# Ruby compiler for sahl to html

=begin
Multiline tags
=end

class Parser
  def initialize(sahl)
    # Load up the raw data and standardize
    @sahl = sahl
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
    @html = "<#{tag}>" + contents + "</#{tag}>"
  end
end

def read(file)
  f = File.new(file, "r").readlines
  f.map! do |line|
    line.delete("\n")
  end
  return f
end

def write
  # Write resultant html to a file
  #htmlName = ARGV[0][0...ARGV[0].length-4] + "html"
  #File.open(htmlName, "w") { |f| f.write("this feature aint workin yet boss") }
end

def convert(input)
  # Convert a line of the file into html
  input.each do |line|
    # Make a copy of original
    ori = line[0..-1]
    parser = Parser.new(line)
    puts "#{ori} -> #{parser.export}"
  end
end

# Take file argument
puts convert(read(ARGV[0]))
