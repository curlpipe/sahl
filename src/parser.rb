# Parser that handles nested brackets

class AttributeParser
  attr_reader :raw
  def initialize(string)
    @string = string
    getRaw
  end
  def getRaw
    return "" if @string == "\n"
    @raw = @string.match(/\.\w*\s*(|\[(.*)\])\s*\{/)[-1].to_s
  end
  def html
    inQuotes = false
    result = ""
    seek = 0
    @raw.chars.each do |ch|
      inQuotes = !inQuotes if ch == '"'
      if ch == ":" && !inQuotes
        whitespace = [@raw.chars[seek-1] == " ", @raw.chars[seek+1] == " "]
        str = ""
        str += " " if !whitespace[0]
        str += "="
        str += " " if !whitespace[1]
        result += str
      elsif ch == "," && !inQuotes
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
  attr_reader :string
  def initialize(string)
    @string = string
    # Regex to get an array of every tag in the string
    @tags = string.scan(/\s*\.(\w*)\s*(\{|\[)/).map!(&:first)
  end
  def [](x)
    tag = getTag(x)
    return tag.match(/\.\w*\s*(|\[.*\]\s*)\{(.*)\}$/)[-1].to_s
  end
  def getTag(x)
    # Get a whole tag with brackets and name
    # Create a substring from where the tag starts to the end
    str = @string[@string.index(@string.match(/(\.#{x}\s*(\{|\[))/).to_s, @tags.count(x))..]
    controller = false
    c = 0
    contents = []
    # Scroll along each character
    str.chars.each do |b|
      if b == "{"
        # When opening a bracket, raise counter and allow exiting
        controller = true
        c += 1
      elsif b == "}"
        # When exiting a bracket, lower counter
        c -= 1
      end
      # Log the whole tag
      contents.push(b)
      # Break when the brackets match and brackets have started
      break if c == 0 unless !controller
    end
    # Return the entire tag (including brackets and tag name)
    return contents.join
  end
  def height(tag)
    # Get the height of a specified tag
    # Create a substring to where the tag starts
    str = @string[..@string.index(@string.match(/(\.#{tag}\s*(|\[.*\])\s*\{)/).to_s, @tags.count(tag))]
    c = 0
    # Use a counter to count the brackets
    str.chars.each do |b|
      if b == "{"
        c += 1
      elsif b == "}"
        c -= 1
      end
    end
    # Return the level that the tag is on
    return c
  end
  def getPeak
    # Get the tag with the highest level in the string
    peak = 0
    peakData = ""
    # For each tag, get the height
    @tags.each do |x|
      th = height(x)
      # If the tag is higher than the previous tags, make it the highest
      if th > peak
        peak = th
        peakData = getTag(x)
      end
    end
    # Return the data and ensure that the tag it returns isn't empty
    unless peakData.empty?
      return peak, peakData
    else
      return 0, @string
    end
  end
end
