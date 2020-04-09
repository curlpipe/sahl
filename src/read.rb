# This function should return all the tags on the different lines in a format that can be parsed
# Basically the standardisation of all tags

def absFilter(input)
  line = input.clone
  line.strip!
  tag = line.match(/\s*\.\w*\s*/).to_s
  has_attr = !line.match(/#{tag}\s*\[/).nil?
  attributes = (has_attr ? line.match(/(#{tag})\s*(\[.*?\]\s*)/)[0].to_s : "")
  if has_attr
    contents = line.sub(/#{tag}\s*\[.*?\]\s*/, "")
  else
    contents = line.sub(/#{tag}\s*/, "")
  end
  has_brackets = contents[0] == "{" && contents[-1] == "}"
  contents = "{#{contents}}" if !has_brackets
  if !has_attr
    result =  "#{tag}#{attributes}#{contents}"
  else
    result = "#{attributes}#{contents}"
  end
  return input.sub(input.strip, result)
end

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
    front = f.shift
    next if front.strip == ""
    if bracketsBalanced?(front) && !isBlank?(front) && front.strip[0] == "."
      front = absFilter(front)
    end
    line += front.clone
    if bracketsBalanced?(line)
      # Brackets are matched
      result.push line
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
