#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.text File.read(File.dirname(__FILE__) + "/../specs/data/utf8.txt"), :alignment => :centre
pdf.pad 5
data = [%w{one two three four}]

data << ["This is some longer text to ensure that the cell wraps","oh noes! the cols can't get the width they desire",3,4]

(1..100).each do
  data << %w{1 2 3 4}
end

t = PDF::Wrapper::Table.new(data)
t.options = {:font_size => 10}
t.row_options[0] = {:color => :white, :fill_color => :black}
t.row_options[6] = {:border => "t"}
t.col_options[0] = {:border => "tb"}
t.col_options[1] = {:alignment => :centre}
t.col_options[2] = {:alignment => :centre}
t.col_options[3] = {:alignment => :centre, :border => "tb"}

pdf.table(t)
pdf.render_to_file("table.pdf")
