# This function should return all the tags on the different lines in a format that can be parsed
# Basically the standardisation of all tags

def bracketsBalanced?(text)
  c = 0
  text.chars.each do |x|
    c += 1 if x == "{"
    c -= 1 if x == "}"
  end
  return c == 0
end

def read(file)
  # Read the file contents to a list
  f = File.open(file, "r").readlines
  result = []
  # Iterate through each line
  line = ""
  until f.empty?
    # Get the tag at the front
    line += f.shift
    if bracketsBalanced? line
      # Brackets are matched
      result << line
      line = ""
    end
  end
  result.map! { |x| 
    x.gsub("\n  ", "!sahlbreak!!sahlspace!") 
     .gsub("  ", "!sahlspace!")
     .gsub("\n}", "!sahlbreak!}")
  }
  return result
end

