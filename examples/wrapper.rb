#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.default_font("Sans Serif")
pdf.default_color(:black)
pdf.text("9780300110562")
pdf.text("9780300110562")
pdf.text("047174719X")
pdf.move_to(100,100)
pdf.text("9780300110562")
#pdf.image("./graph.svg", :left => 100, :top => 250)
pdf.image(File.dirname(__FILE__) + "/google.png", :left => 100, :top => 250)
pdf.render_to_file("wrapper.pdf")
