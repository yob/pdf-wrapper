#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new("wrapper.pdf", :paper => :A4)
pdf.font("Sans Serif")
pdf.text File.read(File.dirname(__FILE__) + "/../specs/data/utf8.txt"), :font => "Monospace", :font_size => 8, :alignment => :center
pdf.finish
