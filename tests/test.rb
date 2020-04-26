require '../src/sahl.rb'

puts "Welcome to the SAHL test suite"

puts "Loading test data"
testdata = File.open("big.sahl", "r").read

puts "Setting up time..."
start = Time.now

puts "Running timing tests..."
9.times {
  main(testdata)
}
tped = main(testdata)
fin = Time.now-start

puts "Running data validation test..."
valid = File.open("big.html", "r").read
passed = tped == valid
File.open("testdump", "w").write(tped)

puts "Here are the results: "
puts "Validation check: ✓ Passed" if passed
puts "Validation check: ❌ Failed" if !passed
`git diff big.html testdump` if !passed
puts "Timing check: ✓ Passed in #{fin} seconds" if fin < 1
puts "Timing check: ❌ Failed in #{fin} seconds" if fin >= 1
