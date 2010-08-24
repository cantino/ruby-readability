require 'rubygems'
require 'open-uri'
require 'lib/readability'

text = open(ARGV.first).read
p Readability::Document.new(text).content
