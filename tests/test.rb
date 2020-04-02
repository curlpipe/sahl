require 'test/unit'
require_relative '../src/parser.rb'
require_relative '../src/read.rb'
require_relative '../src/sahl.rb'

class TestReader < Test::Unit::TestCase
  def test_bracket_imbalance
    testhash = {"{}{}"=>true, "{}{"=>false,
                "{{}{}{}}"=>true, "{}{{}{}"=>false,
                "{{}{{}}{{{}}}}"=>true, "{}}}{}{{{}}}}}{{}"=>false}
    testhash.each { |q, a| assert bracketsBalanced?(q) == a }
  end
  def test_file_basics
    data = read("1.sahl")
    assert data == [".h1{Hello world}\n", "\n", ".p{Hello world}\n", 
                    "!sahlspace!!sahlspace!!sahlspace!!sahlspace!\n", 
                    ".h2 {Subheading}\n", "\n"]
  end
  def test_recursive_basics
    data = read("./2.sahl")
    assert data == [".h1{.b{Hello world}}\n", 
                    ".div {!sahlbreak!!sahlspace!.h1 {Hello world}!sahlbreak!}\n", 
                    "\n"]
  end
  def test_extreme_file
    data = read("./3.sahl")
    assert data == [".ul {!sahlbreak!!sahlspace!.li[class:\"test\", style: \"color: red;\"] {.b{Home}}!sahlbreak!!sahlspace!.li[class :\"test1\"]{Contact}!sahlbreak!!sahlspace!.li [class: \"test2\"] {About}!sahlbreak!!sahlspace!.li [class : \"test3\"]{Help}!sahlbreak!}\n", 
                    "\n", ".p {!sahlbreak!!sahlspace!This .b{element}!sahlbreak!!sahlspace!is on multiple lines!sahlbreak!!sahlspace!wow, isn't this incredible!!sahlbreak!!sahlspace!.b{This .i{is} AMAZING!!!}!sahlbreak!}\n", 
                    "\n", ".div {!sahlbreak!!sahlspace!.div {!sahlbreak!!sahlspace!!sahlspace!Hello world!sahlbreak!!sahlspace!}!sahlbreak!}\n", "\n"]
  end
end

class TestParser < Test::Unit::TestCase
  def test_init
    # Test whitespace and tags
    parser = Parser.new(".h1{Hello world} ")
    parser2 = Parser.new(".h2{Test} .h1 {Hello world} ")
    parser3 = Parser.new(".h1{Hello .i{world}}")
    parser4 = Parser.new(".h1 {Hello .b{world}}")
    assert parser.tags == ["h1"]
    assert parser2.tags == ["h2", "h1"]
    assert parser3.tags == ["h1", "i"]
    assert parser4.tags == ["h1", "b"]
  end
  def test_tagging
    # Test recursive tagging and extraction
    parser = Parser.new(".h1{.b{Bold} .i{Italic}}")
    assert parser["b"] == "Bold"
    assert parser["i"] == "Italic"
    assert parser["h1"] == ".b{Bold} .i{Italic}"
    assert parser.getTag("h1") == ".h1{.b{Bold} .i{Italic}}"
    assert parser.getTag("b") == ".b{Bold}"
    assert parser.getTag("i") == ".i{Italic}"
  end
  def test_height
    # Testing the level of the tags
    test_string = ".h1{.b{BOLD} .h2{.h3{.h4{Hello world}}}}"
    parser = Parser.new(test_string)
    assert parser.height("h1") == 0
    assert parser.height("h2") == 1
    assert parser.height("h3") == 2
    assert parser.height("h4") == 3
    assert parser.height("b") == 1
    assert parser.getPeak == [3, parser.getTag("h4")]
  end
  def test_attributes
    # Test the AttributeParser class to ensure accurate parsing
    attributes = ".h1[style: \"color: green;\"] {Hello world}"
    atparser = AttributeParser.new(attributes)
    assert atparser.raw == "style: \"color: green;\""
    assert atparser.html == "style = \"color: green;\""
    attributes = ".h1[style : \"color: green;\", class :\"Test\"] {Hello world}"
    atparser = AttributeParser.new(attributes)
    assert atparser.raw == "style : \"color: green;\", class :\"Test\""
    assert atparser.html == "style = \"color: green;\" class = \"Test\""
  end
end

class TestSahl < Test::Unit::TestCase
  def test_array_modifications
    array = [1, 2, 2, 3, 4, 5, 3, 6]
    array.chuck 3
    assert array == [1, 2, 2, 4, 5, 3, 6]
    array.chuck 2
    assert array == [1, 2, 4, 5, 3, 6]
    array.chuck 6
    assert array == [1, 2, 4, 5, 3]
  end
  def test_isblank
    testhash = {" ie "=>false, "\n\n\n\n\n"=>true, ""=>true, 
                "hello"=>false, "he\n\nllo"=>false, "\n \n \n \n\n \n \n "=>true}
    testhash.each { |q, a| assert isBlank?(q) == a }
  end
  def test_convert
    assert convert("") == ""
    assert convert(".h1{Hello world}") == "<h1>Hello world</h1>"
    assert convert(".p {Hello world}") == "<p>Hello world</p>"
    attributetag = ".p[class: \"Demo\", style :\"color: green;\"] {Hello world}"
    assert convert(attributetag, attr = AttributeParser.new(attributetag)) == "<p class = \"Demo\" style = \"color: green;\">Hello world</p>"
  end
  def test_convert_line
    assert convertLine("") == ""
    assert convertLine(read("1.sahl")[0]) == "<h1>Hello world</h1>"
    assert convertLine(read("2.sahl")[0]) == "<h1><b>Hello world</b></h1>"
    assert convertLine(read("3.sahl")[0]) == "<ul>\n  <li class = \"test\" style = \"color: red;\"><b>Home</b></li>\n  <li class = \"test1\">Contact</li>\n  <li class = \"test2\">About</li>\n  <li class = \"test3\">Help</li>\n</ul>"
  end
end
