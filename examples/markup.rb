#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new("markup.pdf", :paper => :A4)
pdf.font("Sans Serif")
pdf.color(:black)
pdf.text "<i>James Healy</i>", :font => "Monospace", :font_size => 16, :alignment => :center, :markup => :pango
pdf.finish
