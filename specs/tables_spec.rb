# coding: utf-8

require File.dirname(__FILE__) + '/spec_helper'

context "The PDF::Wrapper class" do
  specify "should be able to draw a table on the canvas using an array of data" do
    pdf = PDF::Wrapper.new
    data = [%w{data1 data2}, %w{data3 data4}]
    pdf.table(data)

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    receiver.content.first.include?("data1").should be_true
    receiver.content.first.include?("data2").should be_true
    receiver.content.first.include?("data3").should be_true
    receiver.content.first.include?("data4").should be_true
  end

  specify "should be able to draw a table on the canvas using a PDF::Wrapper::Table object" do
    pdf = PDF::Wrapper.new
    table = PDF::Wrapper::Table.new do |t|
      t.data = [%w{data1 data2}, %w{data3 data4}]
    end

    pdf.table(table)

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    receiver.content.first.include?("data1").should be_true
    receiver.content.first.include?("data2").should be_true
    receiver.content.first.include?("data3").should be_true
    receiver.content.first.include?("data4").should be_true
  end

  specify "should be able to draw a table on the canvas with no headings" do
    pdf = PDF::Wrapper.new
    
    table = PDF::Wrapper::Table.new do |t|
      t.data = (1..50).collect { [1,2] }
      t.headers ["col1", "col2"]
      t.show_headers = nil
    end

    pdf.table(table)

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    receiver.content.first.include?("col1").should be_false
    receiver.content.first.include?("col2").should be_false
  end

  specify "should be able to draw a table on the canvas with headers on the first page only" do
    pdf = PDF::Wrapper.new
    
    table = PDF::Wrapper::Table.new do |t|
      t.data = (1..50).collect { [1,2] }
      t.headers ["col1", "col2"]
      t.show_headers = :once
    end

    pdf.table(table)

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    receiver.content[0].include?("col1").should be_true
    receiver.content[0].include?("col2").should be_true
    receiver.content[1].include?("col1").should be_false
    receiver.content[1].include?("col2").should be_false
  end

  specify "should be able to draw a table on the canvas with headers on all pages" do
    pdf = PDF::Wrapper.new
    
    table = PDF::Wrapper::Table.new do |t|
      t.data = (1..50).collect { [1,2] }
      t.headers ["col1", "col2"]
      t.show_headers = :page
    end

    pdf.table(table)

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    receiver.content[0].include?("col1").should be_true
    receiver.content[0].include?("col2").should be_true
    receiver.content[1].include?("col1").should be_true
    receiver.content[1].include?("col2").should be_true
  end

  specify "should leave the cursor in the bottom left when adding a table" do
    pdf = PDF::Wrapper.new
    data = [%w{head1 head2},%w{data1 data2}]
    pdf.table(data, :left => pdf.margin_left)
    x,y = pdf.current_point
    x.to_i.should eql(pdf.margin_left)
  end

  specify "should default to using as much available space when adding a table that isn't left aligned with the left margin" do
    pdf = PDF::Wrapper.new
    data = [%w{head1 head2},%w{data1 data2}]
    pdf.table(data, :left => 100)
    x,y = pdf.current_point
    x.to_i.should eql(100)
  end

end
