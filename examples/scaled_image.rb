#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new("scaled_image.pdf", :paper => :A4)
pdf.image(File.dirname(__FILE__) + "/../specs/data/zits.gif",     :top => 100, :height => 200, :width => 200, :proportional => true, :center => true)
pdf.rectangle(pdf.margin_left, 100, 200, 200)
pdf.image(File.dirname(__FILE__) + "/../specs/data/windmill.jpg", :top => 400, :height => 200, :width => 200, :proportional => true, :center => true)
pdf.rectangle(pdf.margin_left, 400, 200, 200)

pdf.finish
