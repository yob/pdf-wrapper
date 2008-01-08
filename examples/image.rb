#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.default_font("Sans Serif")
pdf.default_color(:black)
pdf.text("PDF::Wrapper Supports Images", :alignment => :center)
pdf.image(File.dirname(__FILE__) + "/google.png", :left => 100, :top => 250)
pdf.render_to_file("image.pdf")
