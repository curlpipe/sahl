# Ruby compiler for sahl to html

require './parser.rb'

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
    parser.validTag? ? output << parser.export + "\n" : abort("ERROR: Invalid tag: #{parser.tag}")
  end
  return output
end

# Take file argument
puts convert(read(ARGV[0]))
write(convert(read(ARGV[0])))
#p read(ARGV[0])
