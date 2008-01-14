#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)

pdf.add_repeating_element(:all) do
  pdf.text("Page #{pdf.page}!", :left => pdf.margin_left, :top => pdf.margin_top, :font_size => 18, :alignment => :center)
  pdf.circle(pdf.absolute_x_middle, pdf.absolute_y_middle, 100)
end

pdf.start_new_page
pdf.start_new_page
pdf.start_new_page

pdf.render_to_file("repeating.pdf")
