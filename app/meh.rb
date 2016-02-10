def test
  thing = 2
  yield(thing)
end

result = test do |thing|
  next 4
end

puts result
