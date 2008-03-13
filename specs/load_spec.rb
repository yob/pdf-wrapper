# coding: utf-8

require File.dirname(__FILE__) + '/spec_helper'

context "The PDF::Wrapper class" do
  specify "should load external libs correctly" do
    pdf = PDF::Wrapper.new

    # lib gdkpixbuf
    ::Object.const_defined?(:Gdk).should eql(false)
    pdf.load_libpixbuf
    ::Object.const_defined?(:Gdk).should eql(true)
    ::Gdk.const_defined?(:Pixbuf).should eql(true)

    # pango
    ::Object.const_defined?(:Pango).should eql(false)
    pdf.load_libpango
    ::Object.const_defined?(:Pango).should eql(true)

    # libpoppler
    ::Object.const_defined?(:Poppler).should eql(false)
    pdf.load_libpoppler
    ::Object.const_defined?(:Poppler).should eql(true)

    # librsvg
    ::Object.const_defined?(:RSVG).should eql(false)
    pdf.load_librsvg
    ::Object.const_defined?(:RSVG).should eql(true)

  end
end
