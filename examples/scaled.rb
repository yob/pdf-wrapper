#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.line_width = 2

# grid lines
pdf.line(50, 0, 50, pdf.page_height)
pdf.line(100, 0, 100, pdf.page_height)
pdf.line(150, 0, 150, pdf.page_height)
pdf.line(200, 0, 200, pdf.page_height)
pdf.line(0, 50, pdf.page_width, 50)
pdf.line(0, 100, pdf.page_width, 100)
pdf.line(0, 150, pdf.page_width, 150)
pdf.line(0, 200, pdf.page_width, 200)

# non scaled
pdf.rectangle(100,100,100,100, :fill_color => :green)

# scaled
pdf.scale(pdf.page_width.to_f, pdf.page_height.to_f) do
  #pdf.line_width = 0.005
  # top left corner 10% of the page width from the left and top of the page. 
  # width 10% of the page width
  # height 10% of the page height
  # - obviously will not be square on a A4 page
  pdf.rectangle(0.1,0.1,0.1,0.1, :fill_color => :red)
end

# show results
pdf.render_to_file("scaled.pdf")
