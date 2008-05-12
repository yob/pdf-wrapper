#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

@pdf = PDF::Wrapper.new(:paper => :A4)

def captioned_image(filename, caption, x, y)
  @pdf.translate(x, y) do
    @pdf.image(filename, :top => 0, :left => 0, :height => 100, :width => 100, :proportional => true)
    @pdf.text("Image Caption", :top => 110, :left => 0)
  end
end

captioned_image(File.dirname(__FILE__) + "/../specs/data/orc.svg", "One", 100, 100)
captioned_image(File.dirname(__FILE__) + "/../specs/data/orc.svg", "Two", 250, 300)
captioned_image(File.dirname(__FILE__) + "/../specs/data/orc.svg", "Three", 400, 500)

@pdf.render_to_file("translate.pdf")
