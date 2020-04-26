# frozen_string_literal: true

# The SAHL transpiler 2.1.0
# Author: Luke (@curlpipe)
# Date: April 2020

require 'json'

$caudit = []
$saudit = []
$void = ["area", "base", "br", "col", "embed", "hr", 
        "img", "input", "link", "meta", "param", "source", 
        "track", "wbr", "command", "keygen", "menuitem"]

def index_all(hay, needle)
  r = []
  hay.scan(needle) { |c| r.push $~.offset(0)[0] }
  return r
end

def std(raw)
  # Convert the abstracted tags into normal ones
  result = []
  raw.split("\n").each do |l|
    tag = l.match(/^\s*\.(\w*)(|\s*\[.*?\])\s*\{(.*)\}/m)
    if tag.nil? && !l.strip.empty?
      tag = l.match(/^(\s*)\.(\w*)(|\s*\[.*?\])(?:\s(.*)|)$/)
      unless tag.nil? || l.strip.end_with?("{")
        tag = tag.to_a
        if !tag[4].nil? && tag[4].include?(" //")
          c = tag[4].split(" //")
          tag[4] = c[0..-2].join
          tag.push c[1]
          l = "%s.%s%s {%s} //%s" % tag[1..-1]
        elsif !tag[4].nil? && tag[4].include?("//")
          c = tag[4].split("//")
          tag[4] = c[0..-2].join
          tag.push c[1]
          l = "%s.%s%s {%s} //%s" % tag[1..-1]
        else
          l = "%s.%s%s {%s}" % tag[1..-1]
        end
      end
    end
    result.push l
  end
  return result.join("\n")
end

def stdat(raw)
  tag = raw.scan(/(\[.*?\])/m)
  tag.each { |m| raw.sub!(m[0], m[0].sub(/(\s*\n\s*)/, " ")) }
  return raw
end

def grab(raw, s)
  #Grab a tag at an index
  str = raw[s..-1]
  controller = false
  c = 0
  contents = []
  str.chars.each do |b|
    if b == "{"; controller = true; c += 1
    elsif b == "}"; c -= 1
    end
    contents.push(b)
    break if c == 0 unless !controller
  end
  return contents.join
end

def peak(raw)
  # Find the tag on the highest level
  o = index_all(raw, /\.\w*\s*(\[|\{)/)
  o.each do |tag|
    tag = grab(raw, tag)
    c = tag.match(/\.\w*(?:|\s*\[.*?\])\s*\{(.*?)\}/m)[1]
    return tag if c.match(/\.\w*\{.*?\}/m).nil?
  end
  return nil
end

def attributes(raw)
  # Convert the attributes into HTML
  inQuotes = false
  result = ""
  seek = 0
  raw.chars.each do |ch|
    inQuotes = !inQuotes if ch == '"'
    if ch == ":" && !inQuotes; result += "="
    elsif ch == "," && !inQuotes
    elsif ch == " " && !inQuotes && raw.chars[seek-1] == ":"
    else; result += ch
    end
    seek += 1
  end
  return result[1..-2]
end

def abandon(raw)
  # Index all the script and style tags
  ss = index_all(raw, /\.(style|script)\s*(\[|\{)/)
  tags = []
  ss.each { |i| tags.push grab(raw, i) }
  tags.each_with_index { |t, i| raw.sub!(t, "£#{i}") }
  return raw, tags
end

def comments(raw)
  r = raw.clone
  result = []
  # Inline and single line comments
  str = ""
  raw = raw.chars
  q = false
  capture = false
  loop do
    c = raw.shift
    q = !q if c == "\""
    if c == "/" && raw[0] == "/" && !q
      capture = true
    elsif c == "\n" && !q
      capture = false
      result.push str
      str = ""
    end
    str += c if capture
    if raw.empty?
      result.push str
      break
    end
  end
  # Multiline comments
  raw = r.clone
  str = ""
  raw = raw.chars
  q = false
  capture = false
  loop do
    c = raw.shift
    q = !q if c == "\""
    if c == "/" && raw[0] == "*" && !q
      capture = true
    elsif c == "*" && raw[0] == "/" && !q
      str += c+raw.shift
      capture = false
      result.push str
      str = ""
    end
    str += c if capture
    if raw.empty?
      result.push str
      break
    end
  end
  result.reject!(&:empty?)
  result.each_with_index { |co, i| r.sub!(co, "&#{i}") }
  return r, result
end

def templating(raw)
  result = []
  raw.split("\n").each do |l|
    if l.strip.start_with?("@")
      file = l.strip[1..-1]
      w = l.match(/(\s*)@/)[1].to_s
      if $cdn.include?(file)
        result.push $cdn[file]
        next
      end
      if file.end_with? ".css"
        l = w+".link[rel:\"stylesheet\", type:\"text/css\", href:\"#{file}\"]"
        result.push l
      elsif file.end_with? ".js"
        l = w+".script[type:\"text/javascript\", src:\"#{file}\"]"
        result.push l
      else
        l = File.open(file, "r").readlines.map{ |i| w+i }.join
        l = templating(l) if file.end_with? ".sahl"
        l = l[0..-2] if l.end_with? "\n"
        result.push l
      end
    else
      result.push l
    end
  end
  return result.join "\n"
end

def convert(raw)
  # Convert the tag into HTML
  tag = raw.match(/\.(\w*)(|\s*\[.*?\])\s*\{(.*)\}\s*$/m)
  return if tag.nil?
  tag = tag.to_a
  if $void.include? tag[1]
    return "<#{tag[1]}>#{tag[3]}" if tag[2].empty?
    tag[2] = attributes(tag[2])
    return "<#{tag[1]} #{tag[2]}>#{tag[3]}"
  else
    return "<#{tag[1]}>#{tag[3]}</#{tag[1]}>" if tag[2].empty?
    tag[2] = attributes(tag[2])
    return "<#{tag[1]} #{tag[2]}>#{tag[3]}</#{tag[1]}>"
  end
end

def main(raw)
  # Individually convert the tags and substitute them in
  raw = templating(raw)
  raw = stdat(raw)
  raw = std(raw)
  raw, $saudit = abandon(raw)
  raw, $caudit = comments(raw)
  i = 0
  loop do
    i = peak(raw)
    break if i.nil?
    c = convert(i)
    raw.gsub!(i, c)
  end
  $caudit.each_with_index do |a, i|
    if a.strip.start_with?("//")
      raw.sub!("&#{i}", "<!-- "+a[2..-1]+" -->")
    elsif a.strip.start_with?("/*")
      raw.sub!("&#{i}", "<!-- "+a[2..-3]+" -->")
    end
  end
  $saudit.each_with_index { |a, i| raw.sub!("£#{i}", convert(a)) }
  return "<!DOCTYPE html>\n"+raw
end

#Global templating
$cdn = "{\n    \"bootstrap\":\".meta[charset: \\\"utf-8\\\"]\\n.meta[name: \\\"viewport\\\", content: \\\"width=device-width, initial-scale=1\\\"]\\n.link[href: \\\"https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css\\\", rel: \\\"stylesheet\\\"]\",\n    \"bulma\":\".meta[charset: \\\"utf-8\\\"]\\n.meta[name: \\\"viewport\\\", content: \\\"width=device-width, initial-scale=1\\\"]\\n.link[rel: \\\"stylesheet\\\", href: \\\"https://cdn.jsdelivr.net/npm/bulma@0.8.0/css/bulma.min.css\\\"]\",\n    \"jquery\":\".script[src:\\\"https://code.jquery.com/jquery-3.5.0.min.js\\\", integrity:\\\"sha256-xNzN2a4ltkB44Mc/Jz3pT4iU1cmeR0FkXs4pru/JxaQ=\\\", crossorigin:\\\"anonymous\\\"]\",\n    \"fontawesome\":\".script[defer, src: \\\"https://use.fontawesome.com/releases/v5.3.1/js/all.js\\\"]\",\n    \"opensans\":\".link[href: \\\"https://fonts.googleapis.com/css?family=Open+Sans\\\", rel: \\\"stylesheet\\\", type: \\\"text/css\\\"]\"\n}\n"
$cdn = File.open("sahl.json", "r").read if File.file?("sahl.json")
$cdn = JSON.parse($cdn)

# Command line interface
input = ARGV[0]
output = input.sub(/(\.\w*)$/, ".html")
File.open(output, "w").write(main(File.open(input, "r").read))
