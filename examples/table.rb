#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.text "Chunky Bacon!!"
data = [%w{one two three four}]

data << ["This is some longer text to ensure that the cell wraps",2,3,4]

(1..100).each do
  data << %w{1 2 3 4}
end
pdf.table(data, :font_size => 10)
pdf.render_to_file("wrapper-table.pdf")
