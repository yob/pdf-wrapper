# coding: utf-8

require File.dirname(__FILE__) + '/spec_helper'

context PDF::Wrapper do

  before(:each) { create_pdf }

  specify "should be able to draw a table on the canvas using an array of data" do
    data = [%w{data1 data2}, %w{data3 data4}]
    @pdf.table(data)
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.first.include?("data1").should be_true
    receiver.content.first.include?("data2").should be_true
    receiver.content.first.include?("data3").should be_true
    receiver.content.first.include?("data4").should be_true
  end

  specify "should be able to draw a table on the canvas using an array of TextCells" do
    data = [
      [ PDF::Wrapper::TextCell.new("data1"), PDF::Wrapper::TextCell.new("data2")],
      [ PDF::Wrapper::TextCell.new("data3"), PDF::Wrapper::TextCell.new("data4")]
    ]
    @pdf.table(data)
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.first.include?("data1").should be_true
    receiver.content.first.include?("data2").should be_true
    receiver.content.first.include?("data3").should be_true
    receiver.content.first.include?("data4").should be_true
  end

  specify "should be able to draw a table on the canvas using an array of TextImageCells" do
    filename = File.dirname(__FILE__) + "/data/orc.svg"
    data = [
      [ "data1", PDF::Wrapper::TextImageCell.new("data2", filename, 100, 100)],
      [ "data3", PDF::Wrapper::TextImageCell.new("data4", filename, 100, 100)]
    ]
    @pdf.table(data)
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.first.include?("data1").should be_true
    receiver.content.first.include?("data2").should be_true
    receiver.content.first.include?("data3").should be_true
    receiver.content.first.include?("data4").should be_true
  end

  specify "should be able to draw a table on the canvas using a PDF::Wrapper::Table object" do
    table = PDF::Wrapper::Table.new do |t|
      t.data = [%w{data1 data2}, %w{data3 data4}]
    end

    @pdf.table(table)
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.first.include?("data1").should be_true
    receiver.content.first.include?("data2").should be_true
    receiver.content.first.include?("data3").should be_true
    receiver.content.first.include?("data4").should be_true
  end

  specify "should be able to draw a table on the canvas with no headings" do
    
    table = PDF::Wrapper::Table.new do |t|
      t.data = (1..50).collect { [1,2] }
      t.headers ["col1", "col2"]
      t.show_headers = nil
    end

    @pdf.table(table)
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.first.include?("col1").should be_false
    receiver.content.first.include?("col2").should be_false
  end

  specify "should be able to draw a table on the canvas with headers on the first page only" do
    
    table = PDF::Wrapper::Table.new do |t|
      t.data = (1..50).collect { [1,2] }
      t.headers ["col1", "col2"]
      t.show_headers = :once
    end

    @pdf.table(table)
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content[0].include?("col1").should be_true
    receiver.content[0].include?("col2").should be_true
    receiver.content[1].include?("col1").should be_false
    receiver.content[1].include?("col2").should be_false
  end

  specify "should be able to draw a table on the canvas with headers on all pages" do
    
    table = PDF::Wrapper::Table.new do |t|
      t.data = (1..50).collect { [1,2] }
      t.headers ["col1", "col2"]
      t.show_headers = :page
    end

    @pdf.table(table)
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content[0].include?("col1").should be_true
    receiver.content[0].include?("col2").should be_true
    receiver.content[1].include?("col1").should be_true
    receiver.content[1].include?("col2").should be_true
  end

  specify "should leave the cursor in the bottom left when adding a table" do
    data = [%w{head1 head2},%w{data1 data2}]
    @pdf.table(data, :left => @pdf.margin_left)
    x,y = @pdf.current_point
    x.to_i.should eql(@pdf.margin_left)
  end

  specify "should default to using as much available space when adding a table that isn't left aligned with the left margin" do
    data = [%w{head1 head2},%w{data1 data2}]
    @pdf.table(data, :left => 100)
    x,y = @pdf.current_point
    x.to_i.should eql(100)
  end

end

context PDF::Wrapper, "data= method" do

  specify "should raise an exception if given rows of uneven size" do
    data = [%w{head1 head2},%w{data1}]
    table = PDF::Wrapper::Table.new
    lambda { table.data = data }.should raise_error(ArgumentError)
  end
end
