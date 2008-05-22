#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.rectangle(30,30,100,100, :fill_color => :red)
pdf.circle(100,300,30)
pdf.line(100, 350, 400, 150)
pdf.rectangle(300,300, 200, 200, :fill_color => :green, :radius => 10)
pdf.render_to_file("shapes.pdf")
