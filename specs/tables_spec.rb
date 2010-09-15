# coding: utf-8

require 'spec_helper'

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

  specify "should be able to draw a table with escaped content markup on the canvas" do
    table = PDF::Wrapper::Table.new(:markup => :pango) do |t|
      t.data = [%w{data1 data2}, %w{data3 data4&amp;5}]
    end
    @pdf.table(table)
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.first.include?("data1").should be_true
    receiver.content.first.include?("data2").should be_true
    receiver.content.first.include?("data3").should be_true
    receiver.content.first.include?("data4&5").should be_true
  end

end

context PDF::Wrapper, "data= method" do

  specify "should raise an exception if given rows of uneven size" do
    data = [%w{head1 head2},%w{data1}]
    table = PDF::Wrapper::Table.new
    lambda { table.data = data }.should raise_error(ArgumentError)
  end

  specify "should convert all non cell objects to TextCells" do
    data = [%w{head1 head2},%w{data1 data2}]
    table = PDF::Wrapper::Table.new
    table.data = data
    table.each_cell do |cell|
      cell.should be_a_kind_of(PDF::Wrapper::TextCell)
    end
  end

  specify "should leave existing TextCells unchanged" do
    manual_cell_one = PDF::Wrapper::TextCell.new("data1")
    manual_cell_two = PDF::Wrapper::TextCell.new("data2")
    data = [[manual_cell_one, manual_cell_two]]

    table = PDF::Wrapper::Table.new
    table.data = data

    cells = []
    table.each_cell do |cell|
      cells << cell
    end
    (cells[0] === manual_cell_one).should be_true
    (cells[1] === manual_cell_two).should be_true
  end

  specify "should leave existing TextImageCells unchanged" do
    manual_cell_one = PDF::Wrapper::TextImageCell.new("data1", "image.png", 100, 100)
    manual_cell_two = PDF::Wrapper::TextImageCell.new("data2", "image.png", 100, 100)
    data = [[manual_cell_one, manual_cell_two]]

    table = PDF::Wrapper::Table.new
    table.data = data

    cells = []
    table.each_cell do |cell|
      cells << cell
    end
    (cells[0] === manual_cell_one).should be_true
    (cells[1] === manual_cell_two).should be_true
  end

  specify "should set the default table options on all cells" do
    data = [%w{head1 head2},%w{data1 data2}]
    table = PDF::Wrapper::Table.new(:markup => :pango)

    table.data = data

    table.each_cell do |cell|
      cell.options.should eql(:markup => :pango)
    end
  end
end

context PDF::Wrapper, "headers method" do

  specify "should raise an exception if given cell count does not match existing data" do
    data = [%w{data1 data2},%w{data1 data2}]
    headers = %w{head1}

    table = PDF::Wrapper::Table.new
    table.data = data

    lambda { table.headers(headers) }.should raise_error(ArgumentError)
  end

  specify "should wrap non-cell objects in a TextCell" do
    headers = [["head1","head2"]]

    table = PDF::Wrapper::Table.new
    table.headers(headers)

    set_headers = table.instance_variable_get("@headers")
    set_headers.each do |cell|
      cell.should be_a_kind_of(PDF::Wrapper::TextCell)
    end
  end

  specify "should leave TextCell objects untouched" do
    manual_cell_one = PDF::Wrapper::TextCell.new("data1")
    manual_cell_two = PDF::Wrapper::TextCell.new("data2")
    headers = [manual_cell_one, manual_cell_two]

    table = PDF::Wrapper::Table.new
    table.headers(headers)

    set_headers = table.instance_variable_get("@headers")
    (set_headers[0] === manual_cell_one).should be_true
    (set_headers[1] === manual_cell_two).should be_true
  end

  specify "should leave TextImageCell objects untouched" do
    manual_cell_one = PDF::Wrapper::TextImageCell.new("data1", "image.png", 100, 100)
    manual_cell_two = PDF::Wrapper::TextImageCell.new("data2", "image.png", 100, 100)
    headers = [manual_cell_one, manual_cell_two]

    table = PDF::Wrapper::Table.new
    table.headers(headers)

    set_headers = table.instance_variable_get("@headers")
    (set_headers[0] === manual_cell_one).should be_true
    (set_headers[1] === manual_cell_two).should be_true
  end

  specify "should set options on all cells" do
    headers = ["head1","head2"]

    table = PDF::Wrapper::Table.new
    table.headers(headers, :markup => :pango)

    set_headers = table.instance_variable_get("@headers")
    set_headers.each do |cell|
      cell.options.should eql(:markup => :pango)
    end
  end

  specify "should set default table options on all cells" do
    headers = ["head1","head2"]

    table = PDF::Wrapper::Table.new(:markup => :pango)
    table.headers(headers)

    set_headers = table.instance_variable_get("@headers")
    set_headers.each do |cell|
      cell.options.should eql(:markup => :pango)
    end
  end
end

context PDF::Wrapper, "cell method" do

  specify "should return the appropriate cell" do
    data = [%w{data1 data2},%w{data3 data4}]
    headers = %w{head1}

    table = PDF::Wrapper::Table.new
    table.data = data

    table.cell(0,0).should be_a_kind_of(PDF::Wrapper::TextCell)
    table.cell(0,0).data.should eql("data1")

    table.cell(1,1).should be_a_kind_of(PDF::Wrapper::TextCell)
    table.cell(1,1).data.should eql("data4")
  end
end

context PDF::Wrapper, "cell_options method" do

  specify "should set options on the appropriate cell" do
    data = [%w{data1 data2},%w{data3 data4}]

    table = PDF::Wrapper::Table.new
    table.data = data
    table.cell_options(0,0, :markup => :pango)

    table.cell(0,0).options.should eql(:markup => :pango)
  end
end

context PDF::Wrapper, "col_options method" do

  specify "should set options on all cells in the appropriate column" do
    data = [%w{data1 data2},%w{data3 data4}]

    table = PDF::Wrapper::Table.new
    table.data = data
    table.col_options(0, :markup => :pango)

    table.cell(0,0).options.should eql(:markup => :pango)
    table.cell(0,1).options.should eql(:markup => :pango)
    table.cell(1,0).options.should eql({})
    table.cell(1,1).options.should eql({})
  end
end

context PDF::Wrapper, "row_options method" do

  specify "should set options on all cells in the appropriate row" do
    data = [%w{data1 data2},%w{data3 data4}]

    table = PDF::Wrapper::Table.new
    table.data = data
    table.row_options(0, :markup => :pango)

    table.cell(0,0).options.should eql(:markup => :pango)
    table.cell(1,0).options.should eql(:markup => :pango)
    table.cell(0,1).options.should eql({})
    table.cell(1,1).options.should eql({})
  end
end
