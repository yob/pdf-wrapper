#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.text File.read(File.dirname(__FILE__) + "/../specs/data/utf8.txt").strip, :alignment => :centre
pdf.pad 5
headers = %w{one two three four}

data = []
data << ["This is some longer text to ensure...",2,3,4]
data << ["This is some longer text to ensure...",2,3,4]

table = PDF::Wrapper::Table.new do |t|
  t.data = data
  t.headers = headers
  t.table_options :font_size => 10
  t.header_options :color => :white, :fill_color => :black
  t.manual_col_width [1,2,3], 25
end

pdf.table(table)
pdf.render_file("table.pdf")
