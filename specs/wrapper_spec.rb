# coding: utf-8

require File.dirname(__FILE__) + '/spec_helper'

context "The PDF::Wrapper class" do

  before(:each) { create_pdf }

  specify "should initilize with the correct default paper size and orientation" do
    @pdf.page_width.should eql(PDF::Wrapper::PAGE_SIZES[:A4].first)
    @pdf.page_height.should eql(PDF::Wrapper::PAGE_SIZES[:A4].last)
  end

  specify "should initilize with the correct custom paper size" do
    output = StringIO.new
    pdf = PDF::Wrapper.new(output, :paper => :A0)
    pdf.page_width.should eql(PDF::Wrapper::PAGE_SIZES[:A0].first)
    pdf.page_height.should eql(PDF::Wrapper::PAGE_SIZES[:A0].last)
  end

  specify "should initilize with the correct custom orientation" do
    output = StringIO.new
    pdf = PDF::Wrapper.new(output, :paper => :A4, :orientation => :landscape)
    pdf.page_width.should eql(PDF::Wrapper::PAGE_SIZES[:A4].last)
    pdf.page_height.should eql(PDF::Wrapper::PAGE_SIZES[:A4].first)
  end

  specify "should raise an exception if an invalid orientation is requested" do
    output = StringIO.new
    lambda {pdf = PDF::Wrapper.new(output, :paper => :A4, :orientation => :fake)}.should raise_error(ArgumentError)
  end

  specify "should store sensible default text options" do
    @pdf.default_text_options.should be_a_kind_of(Hash)
  end

  specify "should initilize with the correct default margins (5% of the page)" do
    @pdf.margin_left.should eql((PDF::Wrapper::PAGE_SIZES[:A4].first * 0.05).ceil)
    @pdf.margin_right.should eql((PDF::Wrapper::PAGE_SIZES[:A4].first * 0.05).ceil)
    @pdf.margin_top.should eql((PDF::Wrapper::PAGE_SIZES[:A4].last * 0.05).ceil)
    @pdf.margin_bottom.should eql((PDF::Wrapper::PAGE_SIZES[:A4].last * 0.05).ceil)
  end

  specify "should initilize with the correct default text and colour settings" do
    @pdf.instance_variable_get("@default_font").should eql("Sans Serif")
    @pdf.instance_variable_get("@default_font_size").should eql(16)
  end

  specify "should be able to change the default font" do
    @pdf.font("Arial")
    @pdf.instance_variable_get("@default_font").should eql("Arial")
  end

  specify "should be able to change the default font size" do
    @pdf.font_size(24)
    @pdf.instance_variable_get("@default_font_size").should eql(24)
  end

  specify "should initialize with the cursor at the top left of the body of the page" do
    x,y = @pdf.current_point
    x.to_i.should eql(@pdf.margin_left)
    y.to_i.should eql(@pdf.margin_top)
  end

  specify "should calculate the absolute coordinates for the margins correctly" do
    @pdf.absolute_left_margin.should eql(@pdf.margin_left)
    @pdf.absolute_right_margin.should eql(@pdf.page_width - @pdf.margin_right)
    @pdf.absolute_top_margin.should eql(@pdf.margin_top)
    @pdf.absolute_bottom_margin.should eql(@pdf.page_height - @pdf.margin_bottom)
  end

  specify "should calculate various useful page coordinates correctly" do
    @pdf.absolute_x_middle.should eql(PDF::Wrapper::PAGE_SIZES[:A4].first / 2)
    @pdf.absolute_y_middle.should eql(PDF::Wrapper::PAGE_SIZES[:A4].last / 2)
    @pdf.body_width.should eql(@pdf.page_width - @pdf.margin_left - @pdf.margin_right)
    @pdf.body_height.should eql(@pdf.page_height - @pdf.margin_top - @pdf.margin_bottom)
    @pdf.body_x_middle.should eql(@pdf.margin_left + (@pdf.body_width/ 2))
    @pdf.body_y_middle.should eql(@pdf.margin_top + (@pdf.body_height/ 2))
    @pdf.points_to_bottom_margin(300).should eql(@pdf.absolute_bottom_margin - 300)
    @pdf.points_to_right_margin(300).should eql(@pdf.absolute_right_margin - 300)
  end

  specify "should be able to move the cursor to any arbitary point on the canvas" do
    @pdf.move_to(100,100)
    x,y = @pdf.current_point
    x.to_i.should eql(100)
    y.to_i.should eql(100)
  end

  specify "should be able to shift the y position of the cursor using pad" do
    @pdf.move_to(100,100)
    newy = @pdf.pad(25)
    x,y = @pdf.current_point
    x.to_i.should eql(100)
    y.to_i.should eql(125)
    newy.should eql(125.0)
  end

  specify "should add additional pages at the users request" do
    @pdf.move_to(100,100)
    @pdf.start_new_page
    x,y = @pdf.current_point
    x.to_i.should eql(@pdf.margin_left)
    y.to_i.should eql(@pdf.margin_top)
    @pdf.finish

    # verify the output
    receiver = PageReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)
    receiver.pages.should eql(2)
  end


  specify "should leave the cursor in the bottom left of a layout when new text is added" do
    x, y = @pdf.current_point
    str = "Chunky Bacon!!"
    opts = {:font_size => 16, :font => "Sans Serif", :alignment => :left, :justify => false }
    height = @pdf.text_height(str, @pdf.page_width, opts)
    @pdf.text(str,opts)
    newx, newy = @pdf.current_point

    newx.should eql(x)
    # the top of our text box, plus its height
    newy.should eql(y + height)
  end

  specify "should be able to render to a file" do
    # generate a PDF
    msg = "Chunky Bacon"

    # write the PDF to a temp file
    tmp = Tempfile.open("siftr")
    tmp.close

    pdf = PDF::Wrapper.new(tmp.path)
    pdf.text msg
    pdf.finish

    # ensure an actual PDF was written out
    File.open(tmp.path, "r") do |f|
      f.read(4).should eql("%PDF")
    end

    # remove our temp file
    tmp.unlink
  end

  specify "should be able to determine if a requested colour is valid or not" do
    @pdf.validate_color(:black).should be_true
    @pdf.validate_color([1,0,0]).should be_true
    @pdf.validate_color([1,0,0,0.5]).should be_true
    lambda { @pdf.validate_color(:ponies)}.should raise_error(ArgumentError)
    lambda { @pdf.validate_color([1])}.should raise_error(ArgumentError)
    lambda { @pdf.validate_color([1000, 255, 0])}.should raise_error(ArgumentError)
  end

  specify "should be able to add repeating elements to :all pages" do
    test_str = "repeating"

    @pdf.repeating_element(:all) { |page| page.text test_str }

    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.size.should eql(4)
    receiver.content[0].should eql(test_str)
    receiver.content[1].should eql(test_str)
    receiver.content[2].should eql(test_str)
    receiver.content[3].should eql(test_str)
  end

  specify "should be able to add repeating elements to :odd pages" do
    test_str = "repeating"

    @pdf.repeating_element(:odd) { |page| page.text test_str }

    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.size.should eql(4)
    receiver.content[0].should eql(test_str)
    receiver.content[1].should eql("")
    receiver.content[2].should eql(test_str)
    receiver.content[3].should eql("")
  end

  specify "should be able to add repeating elements to :even pages" do
    test_str = "repeating"

    @pdf.repeating_element(:even) { |page| page.text test_str }

    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.size.should eql(4)
    receiver.content[0].should eql("")
    receiver.content[1].should eql(test_str)
    receiver.content[2].should eql("")
    receiver.content[3].should eql(test_str)
  end

  specify "should be able to add repeating elements to a range of pages" do
    test_str = "repeating"

    @pdf.repeating_element((2..3)) { |page| page.text test_str }

    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.size.should eql(4)
    receiver.content[0].should eql("")
    receiver.content[1].should eql(test_str)
    receiver.content[2].should eql(test_str)
    receiver.content[3].should eql("")
  end

  specify "should be able to add repeating elements to a single page" do
    test_str = "repeating"

    @pdf.repeating_element(2) { |page| page.text test_str }

    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.size.should eql(4)
    receiver.content[0].should eql("")
    receiver.content[1].should eql(test_str)
    receiver.content[2].should eql("")
    receiver.content[3].should eql("")
  end

  specify "should be able to add repeating elements to an array of pages" do
    test_str = "repeating"

    @pdf.repeating_element([1,3,4]) { |page| page.text test_str }

    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.start_new_page
    @pdf.finish

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.content.size.should eql(4)
    receiver.content[0].should eql(test_str)
    receiver.content[1].should eql("")
    receiver.content[2].should eql(test_str)
    receiver.content[3].should eql(test_str)
  end

  specify "should not change the state of the cairo canvas or PDF::Writer defaults (fonts, colors, etc) when adding repeating elements"
  
  specify "should not allow a new page to be started while adding repeating elements" do
    test_str = "repeating"

    lambda do
      @pdf.repeating_element([1,3,4]) do |page|
        page.text test_str
        page.start_new_page
      end
    end.should raise_error(InvalidOperationError)

  end

  specify "should leave the cursor on the bottom left corner of an object when using functions with optional positioning [func(data, opts)]" do
    origx, origy = @pdf.current_point

    # text()
    @pdf.text("Page #{@pdf.page}!", :left => @pdf.margin_left, :top => @pdf.margin_top, :font_size => 18)
    x, y = @pdf.current_point
    x.should eql(origx)
    y.should eql(origy + 27)

    # image() - palms it's works out to helper functions, so we have to check them individually

    # TODO: work out why rcov segfaults when i use the draw_pdf method
    #origx, origy = @pdf.current_point
    #@pdf.draw_pdf(File.dirname(__FILE__) + "/data/utf8-long.pdf", :height => 50)
    #x, y = @pdf.current_point
    #x.should eql(origx)
    #y.should eql(origy + 50)

    origx, origy = @pdf.current_point
    @pdf.draw_pixbuf(File.dirname(__FILE__) + "/data/zits.gif", :height => 50)
    x, y = @pdf.current_point
    x.should eql(origx)
    y.should eql(origy + 50)

    origx, origy = @pdf.current_point
    @pdf.draw_png(File.dirname(__FILE__) + "/data/google.png", :height => 200)
    x, y = @pdf.current_point
    x.should eql(origx)
    y.should eql(origy + 200)

    origx, origy = @pdf.current_point
    @pdf.draw_svg(File.dirname(__FILE__) + "/data/orc.svg", :height => 100)
    x, y = @pdf.current_point
    x.should eql(origx)
    y.should eql(origy + 100)
  end

  specify "should leave the cursor unmodified when using functions with compulsory positioning [func(data, x, y, w, h, opts)]" do
    origx, origy = @pdf.current_point

    # cell()
    @pdf.cell("test", 100, 100, 100, 100)
    x, y = @pdf.current_point
    x.should eql(origx)
    y.should eql(origy)

    # circle()
    @pdf.circle(200, 200, 50)
    x, y = @pdf.current_point
    x.should eql(origx)
    y.should eql(origy)

    # line()
    @pdf.line(300, 200, 350, 300)
    x, y = @pdf.current_point
    x.should eql(origx)
    y.should eql(origy)

    # rectangle()
    @pdf.rectangle(200, 400, 100, 100)
    x, y = @pdf.current_point
    x.should eql(origx)
    y.should eql(origy)
  end

  specify "should maintain an internal counter of pages" do
    @pdf.page.should eql(1)
    @pdf.start_new_page
    @pdf.page.should eql(2)
    @pdf.start_new_page(:pageno => 50)
    @pdf.page.should eql(50)
  end

  specify "should raise an ArgumentError when a function that accepts an options hash is passed an unrecognised option" do
    output = StringIO.new
    lambda { PDF::Wrapper.new(output, :ponies => true)}.should raise_error(ArgumentError)
    lambda { @pdf.cell("test",100,100,100,100, :ponies => true)}.should raise_error(ArgumentError)
    lambda { @pdf.table([[1,2]], :ponies => true)}.should raise_error(ArgumentError)
    lambda { @pdf.text("test", :ponies => true)}.should raise_error(ArgumentError)
    lambda { @pdf.text("test", :ponies => true)}.should raise_error(ArgumentError)
    lambda { @pdf.text_height("test", 100, :ponies => true)}.should raise_error(ArgumentError)
    lambda { @pdf.circle(100,100,100, :ponies => true)}.should raise_error(ArgumentError)
    lambda { @pdf.line(100,100,200,200, :ponies => true)}.should raise_error(ArgumentError)
    lambda { @pdf.rectangle(100,100,100,100, :ponies => true)}.should raise_error(ArgumentError)
    lambda { @pdf.start_new_page(:ponies => true)}.should raise_error(ArgumentError)
    lambda { @pdf.image(File.dirname(__FILE__) + "/data/orc.svg", :ponies => true)}.should raise_error(ArgumentError)
  end

  specify "should allow an existing file to be used as a template for page 1" do
    output = StringIO.new
    pdf = PDF::Wrapper.new(output, :paper => :A4, :template => File.dirname(__FILE__) + "/data/orc.svg")
    pdf.start_new_page
    pdf.finish

    receiver = PageSizeReceiver.new
    reader = PDF::Reader.string(output.string, receiver)

    receiver.pages[0].should eql([0, 0, 734, 772])
    receiver.pages[1].should eql([0, 0, 595.28, 841.89])
  end

  specify "should allow an existing file to be used as a template for page 2" do
    @pdf.start_new_page(:template => File.dirname(__FILE__) + "/data/orc.svg")
    @pdf.finish

    receiver = PageSizeReceiver.new
    reader = PDF::Reader.string(@output.string, receiver)

    receiver.pages[0].should eql([0, 0, 595.28, 841.89])
    receiver.pages[1].should eql([0, 0, 734, 772])
  end

  specify "should correctly convert a user x co-ordinate to device" do
    output = StringIO.new
    pdf = PDF::Wrapper.new(output, :paper => :A4, :margin_left => 40)

    pdf.user_x_to_device_x(10).should eql(10.0)

    # translate so that 0,0 is at the page body corner
    pdf.translate(pdf.margin_left, pdf.margin_top) do
      # a user x co-ord of 10 is now equal to a device co-ord of 50
      pdf.user_x_to_device_x(10).should eql(50.0)
    end
  end

  specify "should correctly convert a user y co-ordinate to device" do
    output = StringIO.new
    pdf = PDF::Wrapper.new(output, :paper => :A4, :margin_top => 40)

    pdf.user_y_to_device_y(10).should eql(10.0)

    # translate so that 0,0 is at the page body corner
    pdf.translate(pdf.margin_left, pdf.margin_top) do
      # a user y co-ord of 10 is now equal to a device co-ord of 50
      pdf.user_y_to_device_y(10).should eql(50.0)
    end
  end

  specify "should correctly convert a device x co-ordinate to user" do
    output = StringIO.new
    pdf = PDF::Wrapper.new(output, :paper => :A4, :margin_left => 40)

    pdf.device_x_to_user_x(10).should eql(10.0)

    # translate so that 0,0 is at the page body corner
    pdf.translate(pdf.margin_left, pdf.margin_top) do
      pdf.device_x_to_user_x(50).should eql(10.0)
    end
  end

  specify "should correctly convert a device y co-ordinate to user" do
    output = StringIO.new
    pdf = PDF::Wrapper.new(output, :paper => :A4, :margin_top => 40)

    pdf.device_y_to_user_y(10).should eql(10.0)

    # translate so that 0,0 is at the page body corner
    pdf.translate(pdf.margin_left, pdf.margin_top) do
      pdf.device_y_to_user_y(50).should eql(10.0)
    end
  end

  specify "should be aware of when the underlying PDFSurface has been finished" do
    @pdf.text "Hi!"
    @pdf.finished?.should be_false
    @pdf.finish
    @pdf.finished?.should be_true
  end
end
