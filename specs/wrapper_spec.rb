# coding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/wrapper'
require 'tempfile'
require 'rubygems'
require 'pdf/reader'

# make some private methods of PDF::Wrapper public for testing
class PDF::Wrapper
  public :build_pango_layout
  public :load_librsvg
  public :load_libpixbuf
  public :load_libpango
  public :load_libpoppler
  public :default_text_options
  public :detect_image_type
  public :draw_pdf
  public :draw_pixbuf
  public :draw_png
  public :draw_svg
  public :validate_color
end

# a helper class for couting the number of pages in a PDF
class PageReceiver
  attr_accessor :page_count

  def initialize
    @page_count = 0
  end

  # Called when page parsing ends
  def end_page
    @page_count += 1
  end
end

class PageTextReceiver
  attr_accessor :content

  def initialize
    @content = []
  end

  # Called when page parsing starts
  def begin_page(arg = nil)
    @content << ""
  end

  def show_text(string, *params)
    @content.last << string.strip
  end

  # there's a few text callbacks, so make sure we process them all
  alias :super_show_text :show_text
  alias :move_to_next_line_and_show_text :show_text
  alias :set_spacing_next_line_show_text :show_text

  def show_text_with_positioning(*params)
    params = params.first
    params.each { |str| show_text(str) if str.kind_of?(String) }
  end

end

context "The PDF::Wrapper class" do

  setup do
    #@file = File.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @shortstr = "Chunky Bacon"
    @medstr   = "This is a medium length string\nthat is also multi line. one two three four."
  end

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

  specify "should initilize with the correct default paper size and orientation" do
    pdf = PDF::Wrapper.new
    pdf.page_width.should eql(PDF::Wrapper::PAGE_SIZES[:A4].first)
    pdf.page_height.should eql(PDF::Wrapper::PAGE_SIZES[:A4].last)
  end

  specify "should initilize with the correct custom paper size" do
    pdf = PDF::Wrapper.new(:paper => :A0)
    pdf.page_width.should eql(PDF::Wrapper::PAGE_SIZES[:A0].first)
    pdf.page_height.should eql(PDF::Wrapper::PAGE_SIZES[:A0].last)
  end

  specify "should initilize with the correct custom orientation" do
    pdf = PDF::Wrapper.new(:paper => :A4, :orientation => :landscape)
    pdf.page_width.should eql(PDF::Wrapper::PAGE_SIZES[:A4].last)
    pdf.page_height.should eql(PDF::Wrapper::PAGE_SIZES[:A4].first)
  end

  specify "should raise an exception if an invalid orientation is requested" do
    lambda {pdf = PDF::Wrapper.new(:paper => :A4, :orientation => :fake)}.should raise_error(ArgumentError)
  end

  specify "should store sensible default text options" do
    pdf = PDF::Wrapper.new
    pdf.default_text_options.should be_a_kind_of(Hash)
  end

  specify "should initilize with the correct default margins (5% of the page)" do
    pdf = PDF::Wrapper.new
    pdf.margin_left.should eql((PDF::Wrapper::PAGE_SIZES[:A4].first * 0.05).ceil)
    pdf.margin_right.should eql((PDF::Wrapper::PAGE_SIZES[:A4].first * 0.05).ceil)
    pdf.margin_top.should eql((PDF::Wrapper::PAGE_SIZES[:A4].last * 0.05).ceil)
    pdf.margin_bottom.should eql((PDF::Wrapper::PAGE_SIZES[:A4].last * 0.05).ceil)
  end

  specify "should initilize with the correct default text and colour settings" do
    pdf = PDF::Wrapper.new
    pdf.instance_variable_get("@default_color").should eql([0.0,0.0,0.0,1.0])
    pdf.instance_variable_get("@default_font").should eql("Sans Serif")
    pdf.instance_variable_get("@default_font_size").should eql(16)
  end

  specify "should initialize with the cursor at the top left of the body of the page" do
    pdf = PDF::Wrapper.new
    x,y = pdf.current_point
    x.to_i.should eql(pdf.margin_left)
    y.to_i.should eql(pdf.margin_top)
  end

  specify "should calculate the absolute coordinates for the margins correctly" do
    pdf = PDF::Wrapper.new
    pdf.absolute_left_margin.should eql(pdf.margin_left)
    pdf.absolute_right_margin.should eql(pdf.page_width - pdf.margin_right)
    pdf.absolute_top_margin.should eql(pdf.margin_top)
    pdf.absolute_bottom_margin.should eql(pdf.page_height - pdf.margin_bottom)
  end

  specify "should calculate various useful page coordinates correctly" do
    pdf = PDF::Wrapper.new
    pdf.absolute_x_middle.should eql(PDF::Wrapper::PAGE_SIZES[:A4].first / 2)
    pdf.absolute_y_middle.should eql(PDF::Wrapper::PAGE_SIZES[:A4].last / 2)
    pdf.body_width.should eql(pdf.page_width - pdf.margin_left - pdf.margin_right)
    pdf.body_height.should eql(pdf.page_height - pdf.margin_top - pdf.margin_bottom)
    pdf.margin_x_middle.should eql(pdf.margin_left + (pdf.body_width/ 2))
    pdf.margin_y_middle.should eql(pdf.margin_top + (pdf.body_height/ 2))
    pdf.points_to_bottom_margin(300).should eql(pdf.absolute_bottom_margin - 300)
    pdf.points_to_right_margin(300).should eql(pdf.absolute_right_margin - 300)
  end

  specify "should be able to move the cursor to any arbitary point on the canvas" do
    pdf = PDF::Wrapper.new
    pdf.move_to(100,100)
    x,y = pdf.current_point
    x.to_i.should eql(100)
    y.to_i.should eql(100)
  end

  specify "should raise an exception if the user tries to move the cursor off the canvas" do
    pdf = PDF::Wrapper.new
    lambda {pdf.move_to(PDF::Wrapper::PAGE_SIZES[:A4].first + 10,100)}.should raise_error(ArgumentError)
    lambda {pdf.move_to(100, PDF::Wrapper::PAGE_SIZES[:A4].last + 10)}.should raise_error(ArgumentError)
  end

  specify "should add additional pages at the users request" do
    pdf = PDF::Wrapper.new
    pdf.move_to(100,100)
    pdf.start_new_page
    x,y = pdf.current_point
    x.to_i.should eql(pdf.margin_left)
    y.to_i.should eql(pdf.margin_top)

    # verify the output
    receiver = PageReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)
    receiver.page_count.should eql(2)
  end

  specify "should be able to draw a single line onto the canvas" do
    x0 = y0 = 100
    x1 = y1 = 200
    pdf = PDF::Wrapper.new
    pdf.line(x0,y0,x1,y1)

    receiver = PDF::Reader::RegisterReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # the begin_new_subpath command specifies the start of the line, append line specifies the end
    receiver.count(:begin_new_subpath).should eql(1)
    receiver.count(:append_line).should eql(1)
    receiver.first_occurance_of(:begin_new_subpath)[:args].should eql([x0.to_f, y0.to_f])
    receiver.first_occurance_of(:append_line)[:args].should eql([x1.to_f, y1.to_f])
  end

  specify "should be able to draw an empty rectangle onto the canvas" do
    x = y = 100
    w = h = 200
    pdf = PDF::Wrapper.new
    pdf.rectangle(x,y,w,h)

    receiver = PDF::Reader::RegisterReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # the begin_new_subpath command specifies the start of the line, append line specifies the end
    callbacks = receiver.series(:begin_new_subpath, :append_line,:append_line,:append_line, :close_subpath)
    callbacks.shift[:args].should eql([x.to_f, y.to_f])
    callbacks.shift[:args].should eql([(x+w).to_f, y.to_f])
    callbacks.shift[:args].should eql([(x+w).to_f, (y+h).to_f])
    callbacks.shift[:args].should eql([x.to_f, (y+h).to_f])
  end

  specify "should leave the cursor in the bottom left of a layout when new text is added" do
    pdf = PDF::Wrapper.new
    x, y = pdf.current_point
    str = "Chunky Bacon!!"
    opts = {:font_size => 16, :font => "Sans Serif", :alignment => :left, :justify => false }
    height = pdf.text_height(str, pdf.page_width, opts)
    pdf.text(str,opts)
    newx, newy = pdf.current_point

    newx.should eql(x)
		# the top of our text box, plus its height
    newy.should eql(y + height)
  end

  specify "should be able to draw a filled rectangle onto the canvas"
=begin
  do
    x = y = 100
    w = h = 200
    pdf = PDF::Wrapper.new
    pdf.rectangle(x,y,w,h, :fill_color => :red)

    receiver = PDF::Reader::RegisterReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # TODO: test for the appropriate pattern of callbacks
  end
=end

  specify "should be able to draw an empty rounded rectangle onto the canvas"
=begin
  do
    x = y = 100
    w = h = 200
    r = 5
    pdf = PDF::Wrapper.new
    pdf.rounded_rectangle(x,y,w,h,r)

    receiver = PDF::Reader::RegisterReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # TODO: test for the appropriate pattern of callbacks
  end
=end

  specify "should be able to draw a filled rounded rectangle onto the canvas"
=begin
  do
    x = y = 100
    w = h = 200
    r = 5
    pdf = PDF::Wrapper.new
    pdf.rounded_rectangle(x,y,w,h,r, :fill_color => :red)

    receiver = PDF::Reader::RegisterReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # TODO: test for the appropriate pattern of callbacks
  end
=end

  specify "should be able to draw an empty circle onto the canvas"
=begin
  do
    x = 100
    y = 200
    r = 5
    pdf = PDF::Wrapper.new
    pdf.circle(x,y,r)

    receiver = PDF::Reader::RegisterReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # TODO: test for the appropriate pattern of callbacks
  end
=end

  specify "should be able to draw a filled circle onto the canvas"
=begin
  do
    x = 100
    y = 200
    r = 5
    pdf = PDF::Wrapper.new
    pdf.circle(x,y,r, :fill_color => :red)

    receiver = PDF::Reader::RegisterReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # TODO: test for the appropriate pattern of callbacks
  end
=end

  specify "should be able to add ascii text to the canvas"
=begin
  do
    msg = "Chunky Bacon"
    pdf = PDF::Wrapper.new
    pdf.text msg

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # TODO: test for the appropriate text on the page. Need to fix unicode spport in pdf-reader first
    #puts receiver.content.inspect
  end
=end

  specify "should be able to add unicode text to the canvas"
=begin
  do
    msg = "メインページ"
    pdf = PDF::Wrapper.new
    pdf.text msg

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # TODO: test for the appropriate text on the page. Need to fix unicode spport in pdf-reader first
    #puts receiver.content.inspect
  end
=end

  specify "should be able to add text to the canvas in a bounding box using the cell method"
=begin
  do
    msg = "メインページ"
    pdf = PDF::Wrapper.new
    pdf.text msg

    receiver = PageTextReceiver.new
    reader = PDF::Reader.string(pdf.render, receiver)

    # TODO: test for the appropriate text on the page. Need to fix unicode spport in pdf-reader first
    #puts receiver.content.inspect
  end
=end

  specify "should be able to render to a file" do
    # generate a PDF
    msg = "Chunky Bacon"
    pdf = PDF::Wrapper.new
    pdf.text msg

    # write the PDF to a temp file
    tmp = Tempfile.open("siftr")
    tmp.close
    pdf.render_to_file(tmp.path)

    # ensure an actual PDF was written out
    File.open(tmp.path, "r") do |f|
      f.read(4).should eql("%PDF")
    end

    # remove our temp file
    tmp.unlink
  end

  specify "should be able to detect the filetype of an image" do
    pdf = PDF::Wrapper.new
    pdf.detect_image_type(File.dirname(__FILE__) + "/data/google.png").should eql(:png)
    pdf.detect_image_type(File.dirname(__FILE__) + "/data/zits.gif").should eql(:gif)
    pdf.detect_image_type(File.dirname(__FILE__) + "/data/orc.svg").should eql(:svg)
    pdf.detect_image_type(File.dirname(__FILE__) + "/data/utf8-long.pdf").should eql(:pdf)
    pdf.detect_image_type(File.dirname(__FILE__) + "/data/shipsail.jpg").should eql(:jpg)
  end

  specify "should be able to calculate the height of a string of text" do
    pdf = PDF::Wrapper.new
    opts = {:font_size => 16, :font => "Sans Serif", :alignment => :left, :justify => false }
    pdf.text_height(@medstr, pdf.body_width, opts).should eql(49)
  end

  specify "should be able to draw a table on the canvas"

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

  specify "should be able to determine if a requested colour is valid or not" do
    pdf = PDF::Wrapper.new
    pdf.validate_color(:black).should be_true
    pdf.validate_color([1,0,0]).should be_true
    pdf.validate_color([1,0,0,0.5]).should be_true
    lambda { pdf.validate_color(:ponies)}.should raise_error(ArgumentError)
    lambda { pdf.validate_color([1])}.should raise_error(ArgumentError)
    lambda { pdf.validate_color([1000, 255, 0])}.should raise_error(ArgumentError)
  end

  specify "should be able to add repeating elements to various pages (:all, :odd, :even, :range, int)"

  specify "should not change the state of the cairo canvas or PDF::Writer defaults (fonts, colors, etc) when adding repeating elements"

  specify "should leave the cursor on the bottom left corner of an object when using functions with optional positioning [func(data, opts)]" do
    pdf = PDF::Wrapper.new
    origx, origy = pdf.current_point

    # text()
    pdf.text("Page #{pdf.page}!", :left => pdf.margin_left, :top => pdf.margin_top, :font_size => 18)
    x, y = pdf.current_point
    x.should eql(origx)
    y.should eql(origy + 26.25)

    # image() - palms it's works out to helper functions, so we have to check them individually

    # TODO: work out why rcov segfaults when i use the draw_pdf method
    #origx, origy = pdf.current_point
    #pdf.draw_pdf(File.dirname(__FILE__) + "/data/utf8-long.pdf", :height => 50)
    #x, y = pdf.current_point
    #x.should eql(origx)
    #y.should eql(origy + 50)

    origx, origy = pdf.current_point
    pdf.draw_pixbuf(File.dirname(__FILE__) + "/data/zits.gif", :height => 50)
    x, y = pdf.current_point
    x.should eql(origx)
    y.should eql(origy + 50)

    origx, origy = pdf.current_point
    pdf.draw_png(File.dirname(__FILE__) + "/data/google.png", :height => 200)
    x, y = pdf.current_point
    x.should eql(origx)
    y.should eql(origy + 200)

    origx, origy = pdf.current_point
    pdf.draw_svg(File.dirname(__FILE__) + "/data/orc.svg", :height => 100)
    x, y = pdf.current_point
    x.should eql(origx)
    y.should eql(origy + 100)
  end

  specify "should leave the cursor unmodified when using functions with compulsory positioning [func(data, x, y, w, h, opts)]" do
    pdf = PDF::Wrapper.new
    origx, origy = pdf.current_point

    # cell()
    pdf.cell("test", 100, 100, 100, 100)
    x, y = pdf.current_point
    x.should eql(origx)
    y.should eql(origy)

    # circle()
    pdf.circle(200, 200, 50)
    x, y = pdf.current_point
    x.should eql(origx)
    y.should eql(origy)

    # line()
    pdf.line(300, 200, 350, 300)
    x, y = pdf.current_point
    x.should eql(origx)
    y.should eql(origy)

    # rectangle()
    pdf.rectangle(200, 400, 100, 100)
    x, y = pdf.current_point
    x.should eql(origx)
    y.should eql(origy)

    # rounded_rectangle()
    pdf.rounded_rectangle(200, 400, 100, 100, 10)
    x, y = pdf.current_point
    x.should eql(origx)
    y.should eql(origy)
  end

  specify "should maintain an internal counter of pages" do
    pdf = PDF::Wrapper.new
    pdf.page.should eql(1)
    pdf.start_new_page
    pdf.page.should eql(2)
    pdf.start_new_page(50)
    pdf.page.should eql(50)
  end
end
