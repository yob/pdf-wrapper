#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.default_font("Sans Serif")
pdf.default_color(:black)
pdf.text "<i>James Healy</i>", :font => "Monospace", :font_size => 16, :alignment => :center, :markup => :pango
pdf.render_to_file("markup.pdf")
