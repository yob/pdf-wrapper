#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.text File.read(File.dirname(__FILE__) + "/../specs/data/utf8.txt").strip, :alignment => :centre
pdf.pad 5
headers = %w{one two three four}

data = []
data << ["This is some longer text to ensure that the cell wraps","oh noes! the cols can't get the width they desire",3,4]
data << ["This is some longer text to ensure that the cell wraps","oh noes! the cols can't get the width they desire",3,4]

data << [[], "j", "a", "m"]

(1..100).each do
  data << %w{1 2 3 4}
end

table = PDF::Wrapper::Table.new(:font_size => 10) do |t|
  t.data = data
  t.headers headers, {:color => :white, :fill_color => :black}
  t.row_options 6, {:border => "t"}
  t.row_options :even, {:fill_color => :gray}
  t.col_options 0, {:border => "tb"}
  t.col_options 1, {:alignment => :centre}
  t.col_options 2, {:alignment => :centre}
  t.col_options 3, {:alignment => :centre, :border => "tb"}
  t.col_options :even, {:fill_color => :blue}
  t.cell_options 3, 3, {:fill_color => :green}
end

pdf.table(table)
pdf.render_file("table.pdf")
