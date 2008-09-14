#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new("repeating.pdf", :paper => :A4)

pdf.repeating_element(:all) do
  pdf.text("Page #{pdf.page}!", :left => pdf.margin_left, :top => pdf.margin_top, :font_size => 18, :alignment => :center)
end

pdf.repeating_element(:even) do
  pdf.circle(pdf.absolute_x_middle, pdf.absolute_y_middle, 100)
end

pdf.repeating_element(:odd) do
  pdf.rectangle(pdf.absolute_x_middle, pdf.absolute_y_middle, 100, 100)
end

pdf.repeating_element([1,2]) do
  pdf.rectangle(pdf.absolute_x_middle, pdf.absolute_y_middle, 100, 100, :radius => 5)
end

pdf.repeating_element(3) do
  pdf.line(pdf.absolute_x_middle, pdf.absolute_y_middle, 100, 100)
end

pdf.repeating_element((3..4)) do
  pdf.circle(400, 400, 100, :color => :red)
end

pdf.start_new_page
pdf.start_new_page
pdf.start_new_page

pdf.finish
