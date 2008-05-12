#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.rectangle(100,100,50,50, :fill_color => :green)
pdf.scale do
  pdf.rectangle(100,100,50,50, :fill_color => :red)
end
pdf.render_to_file("scaled.pdf")
