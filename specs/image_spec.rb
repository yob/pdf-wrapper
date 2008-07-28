# coding: utf-8

require File.dirname(__FILE__) + '/spec_helper'

context "The PDF::Wrapper class" do
  specify "should be able to detect the filetype of an image" do
    pdf = PDF::Wrapper.new
    pdf.detect_image_type(File.dirname(__FILE__) + "/data/google.png").should eql(:png)
    pdf.detect_image_type(File.dirname(__FILE__) + "/data/zits.gif").should eql(:gif)
    pdf.detect_image_type(File.dirname(__FILE__) + "/data/orc.svg").should eql(:svg)
    pdf.detect_image_type(File.dirname(__FILE__) + "/data/utf8-long.pdf").should eql(:pdf)
    pdf.detect_image_type(File.dirname(__FILE__) + "/data/shipsail.jpg").should eql(:jpg)
  end

  specify "should be able to determine image dimensions correctly" do
    pdf = PDF::Wrapper.new
    pdf.image_dimensions(File.dirname(__FILE__) + "/data/google.png").should eql([166,55])
    pdf.image_dimensions(File.dirname(__FILE__) + "/data/zits.gif").should eql([525,167])
    pdf.image_dimensions(File.dirname(__FILE__) + "/data/orc.svg").should eql([734, 772])
    pdf.image_dimensions(File.dirname(__FILE__) + "/data/utf8-long.pdf").map{ |d| d.to_i}.should eql([595,841])
    pdf.image_dimensions(File.dirname(__FILE__) + "/data/shipsail.jpg").should eql([192,128])
  end

  specify "should be able to calculate scaled image dimensions correctly" do
    pdf = PDF::Wrapper.new
    pdf.calc_image_dimensions(100, 100, 200, 200).should eql([100.0,100.0])
    pdf.calc_image_dimensions(nil, nil, 200, 200).should eql([200.0,200.0])
    pdf.calc_image_dimensions(150, 200, 200, 200, true).should eql([150.0,150.0])
    pdf.calc_image_dimensions(300, 250, 200, 200, true).should eql([250.0,250.0])
  end

  specify "should be able to draw rotated images correctly" do
    pdf = PDF::Wrapper.new
    pdf.image(File.dirname(__FILE__) + "/data/shipsail.jpg", :rotate => :clockwise)
    pdf.image(File.dirname(__FILE__) + "/data/shipsail.jpg", :rotate => :counterclockwise)
    pdf.image(File.dirname(__FILE__) + "/data/shipsail.jpg", :rotate => :upsidedown)
    pdf.image(File.dirname(__FILE__) + "/data/shipsail.jpg", :rotate => :none)
  end

  specify "should be able to draw an image with padding correctly"
end
