require './models/books'

book = Books.new
print "Attempting to add ISBN #{ARGV[0]}"
action = book.create "#{ARGV[0]}".to_s
if action[0] == true
  exit(0)
else
  exit(1)
end

