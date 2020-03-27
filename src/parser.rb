# Sahl tag parser

require 'json'

class Parser
  attr_reader :multiline, :tag
  def initialize(sahl)
    # get list of valid html tags
    tagsFile = open("assets/validTags.json")
    @validTags = JSON.parse(tagsFile.read)["validTags"]
    tagsFile.close
    # Load up the raw data and standardize
    @sahl = sahl
    @multiline = $mltable[@sahl]
    @tag = tag
    @attributes = cutAttributes
    standardize
  end
  def standardize
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
  def cutAttributes
    # Remove attributes, and store separately
    attributes = ""
    # Check if attributes exist
    if @sahl[@tag.length] != "("
      return attributes
    else
      # Capture string up to the closing bracket that corresponds with the original opening bracket
      # I couldn't find an obvious way to do this with regex
      openBrackets = 1
      closedBrackets = 0
      index = @tag.length + 1
      while closedBrackets != openBrackets
        attributes << @sahl[index]
        if @sahl[index] == "("
          openBrackets += 1
        elsif @sahl[index] == ")"
          closedBrackets += 1
        end
        index += 1
      end
    end
    @sahl.sub!("("+attributes, "")
    return attributes.chomp(")").insert(0, " ")
  end
  def contents
    # Extract the contents of the tag
    @sahl.match(/{(.*)}/).to_s[1...-1]
  end
  def export
    # Export to html
    @multiline ? @html = "<#{tag}#{@attributes}>\n  #{contents}\n</#{tag}>" : @html = "<#{tag}#{@attributes}>#{contents}</#{tag}>"
    @html.gsub!("!sahlbreak!", "\n  ")
    return @html
  end
    # Check whether tag exists in HTML
  def validTag?
    @validTags.include? @tag
  end
end
