#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.font("Sans Serif")
pdf.text File.read(File.dirname(__FILE__) + "/../specs/data/utf8-long.txt"), :font => "Monospace", :font_size => 8, :top => 300
pdf.render_to_file("utf8-long.pdf")
