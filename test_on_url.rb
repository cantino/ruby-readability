require 'rubygems'
require 'open-uri'
require 'readability'

text = open(ARGV.first).read
p Readability::Document.new(text).content
