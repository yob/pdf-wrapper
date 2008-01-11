#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.default_font("Sans Serif")
pdf.default_color(:black)
pdf.text File.read(File.dirname(__FILE__) + "/../specs/data/utf8-long.txt"), :font => "Monospace", :font_size => 8
pdf.render_to_file("utf8-long.pdf")
