# coding: utf-8

require File.dirname(__FILE__) + '/spec_helper'

context "The PDF::Wrapper class" do
  specify "should be able to add ascii text to the canvas" do
    msg = "Chunky Bacon"
    pdf = PDF::Wrapper.new
    pdf.text msg

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # TODO: test for the text is in the appropriate location on the page
    receiver.content.first.should eql(msg)
  end

  specify "should be able to add unicode text to the canvas" do
    msg = "メインページ"
    pdf = PDF::Wrapper.new
    pdf.text msg

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # TODO: test for the text is in the appropriate location on the page
    receiver.content.first.should eql(msg)
  end

  specify "should be able to add text to the canvas in a bounding box using the cell method" do
    msg = "メインページ"
    pdf = PDF::Wrapper.new
    pdf.cell msg, 100, 100, 200, 200

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # TODO: test for the text is in the appropriate location on the page
    receiver.content.first.should eql(msg)
  end

  specify "should keep all text for a cell inside the cell boundaries" do
    msg = "This is a text cell, added by James"
    pdf = PDF::Wrapper.new
    x = y = 100
    w = h = 200
    pdf.cell msg, x, y, w, h

    receiver = PDF::Reader::RegisterReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    receiver.all(:set_text_matrix_and_text_line_matrix).each do |cb|
      # horizontal location
      # TODO: we're only testing the it doesn't start past the right boundary of the cell
      #       should also test that it doesn't start in the cell but overrun it
      (cb[:args][4] >= x).should     be_true
      (cb[:args][4] <= x + w).should be_true

      # vertical location
      # TODO: we're only testing the it doesn't start past the bottom boundary of the cell
      #       should also test that it doesn't start in the cell but overrun it
      cell_top_bound = pdf.page_height - y
      (cb[:args][5] <= cell_top_bound).should     be_true
      (cb[:args][5] >= cell_top_bound - h).should be_true
    end
  end

  specify "should be able to calculate the height of a string of text" do
    str   = "This is a medium length string\nthat is also multi line. one two three four."
    pdf = PDF::Wrapper.new
    opts = {:font_size => 16, :font => "Sans Serif", :alignment => :left, :justify => false }
    pdf.text_height(str, pdf.body_width, opts).should eql(49)
  end

  specify "should raise an exception if build_pango_layout is passed anything other than a string" do
    pdf = PDF::Wrapper.new
    lambda { pdf.build_pango_layout(10) }.should raise_error(ArgumentError)
  end

  if RUBY_VERSION >= "1.9"
    specify "should accept non UTF-8 strings to build_pango_layout and convert them on the fly" do
      pdf = PDF::Wrapper.new

      # all three of these files have the same content, but in different encodings
      iso2022_str  = File.open(File.dirname(__FILE__) + "/data/shift_jis.txt", "r:ISO-2022-JP") { |f| f.read }.strip!
      shiftjis_str = File.open(File.dirname(__FILE__) + "/data/iso-2022-jp.txt", "r:Shift_JIS") { |f| f.read }.strip!
      utf8_str     = File.open(File.dirname(__FILE__) + "/data/utf8.txt", "r:UTF-8") { |f| f.read }.strip!

      pdf.build_pango_layout(shiftjis_str)
      pdf.build_pango_layout(iso2022_str)

      # TODO: improve this spec using mocks. Atm, I'm assume that if build_pango_layout didn't raise an exception when
      #       passed in the non UTF-8 strings, then all worked fine. yuck.
    end

    specify "should raise an error when a string that isn't convertable to UTF-8 is passed into build_pango_layout()"
  end
end
