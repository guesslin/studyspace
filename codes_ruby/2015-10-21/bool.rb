#!/usr/bin/env ruby
def bar?
	return false
end

def foo
	return if bar?
	puts "foo"
	puts "bar"
end

foo
