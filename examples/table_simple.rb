#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new("table.pdf", :paper => :A4)

data = []
data << ["This is some longer text to ensure that the cell wraps","oh noes! the cols can't get the width they desire",3,4]
data << ["This is some longer text to ensure that the cell wraps","oh noes! the cols can't get the width they desire",3,4]
data << [[], "j", "a", "m"]

(1..100).each do
  data << %w{1 2 3 4}
end

pdf.table(data)
pdf.finish
