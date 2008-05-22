#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.font("Sans Serif")
pdf.color(:black)
pdf.text("PDF::Wrapper Supports Images", :alignment => :center)
pdf.image(File.dirname(__FILE__) + "/../specs/data/zits.gif")
pdf.image(File.dirname(__FILE__) + "/../specs/data/google.png", :left => 100, :top => 350)
pdf.image(File.dirname(__FILE__) + "/../specs/data/stef.jpg", :left => 200, :top => 500)
pdf.start_new_page
pdf.image(File.dirname(__FILE__) + "/../specs/data/orc.svg", :left => pdf.margin_left, :top => pdf.margin_top, :width => pdf.body_width, :height => pdf.body_height)
pdf.start_new_page
pdf.image(File.dirname(__FILE__) + "/../specs/data/utf8-long.pdf", :left => pdf.margin_left, :top => pdf.margin_top, :width => pdf.body_width/2, :height => pdf.body_height/2)
pdf.color(:red)

pdf.render_to_file("image.pdf")
