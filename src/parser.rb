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
    @multiline ? @html = "<#{tag}>\n  #{contents}\n</#{tag}>" : @html = "<#{tag}>#{contents}</#{tag}>"
    @html.gsub!("!sahlbreak!", "\n  ")
    return @html
  end
    # Check whether tag exists in HTML
  def validTag?
    @validTags.include? @tag
  end
end
