# coding: utf-8

require 'stringio'
require 'pdf/core'
require 'pdf/errors'

require File.dirname(__FILE__) + "/wrapper/graphics"
require File.dirname(__FILE__) + "/wrapper/images"
require File.dirname(__FILE__) + "/wrapper/loading"
require File.dirname(__FILE__) + "/wrapper/table"
require File.dirname(__FILE__) + "/wrapper/text"
require File.dirname(__FILE__) + "/wrapper/page"

require 'rubygems'
gem 'cairo', '>=1.5'
require 'cairo'

module PDF
  # Create PDF files by using the cairo and pango libraries.
  #
  # Rendering to a file:
  #
  #   require 'pdf/wrapper'
  #   pdf = PDF::Wrapper.new(:paper => :A4)
  #   pdf.text "Hello World"
  #   pdf.render_to_file("wrapper.pdf")
  #
  # Rendering to a string:
  #
  #   require 'pdf/wrapper'
  #   pdf = PDF::Wrapper.new(:paper => :A4)
  #   pdf.text "Hello World", :font_size => 16
  #   puts pdf.render
  #
  # Changing the default font:
  #
  #   require 'pdf/wrapper'
  #   pdf = PDF::Wrapper.new(:paper => :A4)
  #   pdf.font("Monospace")
  #   pdf.text "Hello World", :font => "Sans Serif", :font_size => 18
  #   pdf.text "Pretend this is a code sample"
  #   puts pdf.render
  class Wrapper

    attr_reader :page

    # borrowed from PDF::Writer
    PAGE_SIZES = { # :value {...}:
      #:4A0   => [4767.87, 6740.79], :2A0    => [3370.39, 4767.87],
      :A0    => [2383.94, 3370.39], :A1     => [1683.78, 2383.94],
      :A2    => [1190.55, 1683.78], :A3     => [841.89, 1190.55],
      :A4    => [595.28,  841.89],  :A5     => [419.53,  595.28],
      :A6    => [297.64,  419.53],  :A7     => [209.76,  297.64],
      :A8    => [147.40,  209.76],  :A9     => [104.88,  147.40],
      :A10   => [73.70,  104.88],   :B0     => [2834.65, 4008.19],
      :B1    => [2004.09, 2834.65], :B2     => [1417.32, 2004.09],
      :B3    => [1000.63, 1417.32], :B4     => [708.66, 1000.63],
      :B5    => [498.90,  708.66],  :B6     => [354.33,  498.90],
      :B7    => [249.45,  354.33],  :B8     => [175.75,  249.45],
      :B9    => [124.72,  175.75],  :B10    => [87.87,  124.72],
      :C0    => [2599.37, 3676.54], :C1     => [1836.85, 2599.37],
      :C2    => [1298.27, 1836.85], :C3     => [918.43, 1298.27],
      :C4    => [649.13,  918.43],  :C5     => [459.21,  649.13],
      :C6    => [323.15,  459.21],  :C7     => [229.61,  323.15],
      :C8    => [161.57,  229.61],  :C9     => [113.39,  161.57],
      :C10   => [79.37,  113.39],   :RA0    => [2437.80, 3458.27],
      :RA1   => [1729.13, 2437.80], :RA2    => [1218.90, 1729.13],
      :RA3   => [864.57, 1218.90],  :RA4    => [609.45,  864.57],
      :SRA0  => [2551.18, 3628.35], :SRA1   => [1814.17, 2551.18],
      :SRA2  => [1275.59, 1814.17], :SRA3   => [907.09, 1275.59],
      :SRA4  => [637.80,  907.09],  :LETTER => [612.00,  792.00],
      :LEGAL => [612.00, 1008.00],  :FOLIO  => [612.00,  936.00],
      :EXECUTIVE => [521.86, 756.00]
    }

    # create a new PDF::Wrapper class to compose a PDF document
    # Options:
    # <tt>:paper</tt>::   The paper size to use (default :A4)
    # <tt>:orientation</tt>::   :portrait (default) or :landscape
    # <tt>:background_color</tt>::   The background colour to use (default :white)
    # <tt>:margin_top</tt>::   The size of the default top margin (default 5% of page)
    # <tt>:margin_bottom</tt>::   The size of the default bottom margin (default 5% of page)
    # <tt>:margin_left</tt>::   The size of the default left margin (default 5% of page)
    # <tt>:margin_right</tt>::   The size of the default right margin (default 5% of page)
    # <tt>:template</tt>::  The path to an image file. If specified, the first page of the document will use the specified image as a template.
    #                       The page will be sized to match the template size. The use templates on subsequent pages, see the options for
    #                       start_new_page.
    def initialize(opts={})
      # TODO: Investigate ways of using the cairo transform/translate/scale functionality to
      #       reduce the amount of irritating co-ordinate maths the user of PDF::Wrapper (ie. me!)
      #       is required to do.
      #       - translate the pdf body width so that it's 1.0 wide and 1.0 high?
      # TODO: find a way to add metadata (title, author, subject, etc) to the output file
      #       currently no way to specify this in cairo.
      #       tentatively scheduled for cairo 1.8 - see:
      #       - http://cairographics.org/roadmap/
      #       - http://lists.cairographics.org/archives/cairo/2007-September/011441.html
      #       - http://lists.freedesktop.org/archives/cairo/2006-April/006809.html

      # ensure we have recentish cairo bindings
      raise "Ruby Cairo bindings version #{Cairo::BINDINGS_VERSION.join(".")} is too low. At least 1.5 is required" if Cairo::BINDINGS_VERSION.to_s < "150"

      options = {:paper => :A4,
                  :orientation => :portrait,
                  :background_color => :white
                 }
      options.merge!(opts)

      # test for invalid options
      options.assert_valid_keys(:paper, :orientation, :background_color, :margin_left, :margin_right, :margin_top, :margin_bottom, :template)

      set_dimensions(options[:orientation], options[:paper])

      # set page margins and dimensions of usable canvas
      @margin_left = options[:margin_left] || (@page_width * 0.05).ceil
      @margin_right = options[:margin_right] || (@page_width * 0.05).ceil
      @margin_top = options[:margin_top] || (@page_height * 0.05).ceil
      @margin_bottom = options[:margin_bottom] || (@page_height * 0.05).ceil

      # initialize some cairo objects to draw on
      @output = StringIO.new
      @surface = Cairo::PDFSurface.new(@output, @page_width, @page_height)
      @context = Cairo::Context.new(@surface)

      # set the background colour
      color(options[:background_color])
      @context.paint

      # set a default drawing colour and font style
      color(:black)
      line_width(0.5)
      font("Sans Serif")
      font_size(16)

      # maintain a count of pages and array of repeating elements to add to each page
      @page = 1
      @repeating = []

      # build the first page from a template if required
      if opts[:template]
        w, h = image_dimensions(opts[:template])
        @surface.set_size(w, h)
        image(opts[:template], :left => 0, :top => 0)
      end

      # move the cursor to the top left of the usable canvas
      reset_cursor
    end

    #####################################################
    # Functions relating to calculating various page dimensions
    #####################################################

    # Returns the x value of the left margin
    # The top left corner of the page is (0,0)
    def absolute_left_margin
      margin_left
    end

    # Returns the x value of the right margin
    # The top left corner of the page is (0,0)
    def absolute_right_margin
      page_width - margin_right
    end

    # Returns the y value of the top margin
    # The top left corner of the page is (0,0)
    def absolute_top_margin
      margin_top
    end

    # Returns the y value of the bottom margin
    # The top left corner of the page is (0,0)
    def absolute_bottom_margin
      page_height - margin_bottom
    end

    # Returns the x at the middle of the page
    def absolute_x_middle
      page_width / 2
    end

    # Returns the y at the middle of the page
    def absolute_y_middle
      page_height / 2
    end

    # Returns the width of the usable part of the page (between the side margins)
    def body_width
      device_x_to_user_x(@page_width - @margin_left - @margin_right)
    end

    # Returns the height of the usable part of the page (between the top and bottom margins)
    def body_height
      #@context.device_to_user(@page_width - @margin_left - @margin_right, @page_height - @margin_top - @margin_bottom).last
      device_y_to_user_y(@page_height - @margin_top - @margin_bottom)
    end

    # Returns the x coordinate of the middle part of the usable space between the margins
    def body_x_middle
      margin_left + (body_width / 2)
    end

    # Returns the y coordinate of the middle part of the usable space between the margins
    def body_y_middle
      margin_top + (body_height / 2)
    end

    def page_height
      device_y_to_user_y(@page_height)
    end

    def page_width
      device_x_to_user_x(@page_width)
    end

    # return the current position of the cursor
    # returns 2 values - x,y
    def current_point
      @context.current_point
    end

    def x
      @context.current_point.first
    end

    def y
      @context.current_point.last
    end

    def margin_bottom
      device_y_to_user_y(@margin_bottom).to_i
    end

    def margin_left
      device_x_to_user_x(@margin_left).to_i
    end

    def margin_right
      device_x_to_user_x(@margin_right).to_i
    end

    def margin_top
      device_y_to_user_y(@margin_top).to_i
    end

    # return the number of points from  starty to the bottom border
    def points_to_bottom_margin(starty)
      absolute_bottom_margin - starty
    end

    # return the number of points from  startx to the right border
    def points_to_right_margin(startx)
      absolute_right_margin - startx
    end

    # Set a new location to be the origin (0,0). This is useful for repetitive tasks
    # where objects need to be added to the canvas at regular offsets, and can save
    # a significant amount of irritating co-ordinate maths.
    #
    # As an example, consider the following code fragment. If you have a series of images
    # to arrange on a page with identical sizes, translate can help keep the code clean
    # and readable by reducing (or removing completely) the need to perform a series of
    # basic sums to calculate the correct offsets, etc.
    #
    #   def captioned_image(filename, caption, x, y)
    #     @pdf.translate(x, y) do
    #       @pdf.image(filename, :top => 0, :left => 0, :height => 100, :width => 100, :proportional => true)
    #       @pdf.text(caption, :top => 110, :left => 0, :width => 100)
    #     end
    #   end
    #
    #   captioned_image("orc.svg", "Orc", 100, 100)
    #   captioned_image("hobbit.svg", "Hobbit", 100, 400)
    #   captioned_image("elf.svg", "Elf", 100, 400)
    def translate(x, y, &block)
      @context.save do
        @context.translate(x, y)
        move_to(0,0)
        yield
      end
    end

    # change the default colour used to draw on the canvas
    #
    # Parameters:
    # <tt>c</tt>::  either a colour symbol recognised by rcairo (:red, :blue, :black, etc) or
    #               an array with 3-4 integer elements. The first 3 numbers are red, green and
    #               blue (0-255). The optional 4th number is the alpha channel and should be
    #               between 0 and 1. See the API docs at http://cairo.rubyforge.org/ for a list
    #               of predefined colours
    def color(c)
      c = translate_color(c)
      validate_color(c)
      @context.set_source_rgba(*c)
    end
    alias color= color

    #####################################################
    # Functions relating to generating the final document
    #####################################################

    # render the PDF and return it as a string
    def render
      # finalise the document, then convert the StringIO object it was rendered to
      # into a string
      finish
      return @output.string
    end

    def render_to_file(filename) #nodoc
      # TODO: remove this at some point. Deprecation started on 24th July 2008
      warn "WARNING: render_to_file() is deprecated, please use render_file()"
      render_file filename
    end

    # save the rendered PDF to a file
    def render_file(filename)
      finish

      # write each line from the StringIO object it was rendered to into the
      # requested file
      File.open(filename, "w") do |of|
        @output.rewind
        @output.each_line { |line| of.write(line) }
      end
    end

    #####################################################
    # Misc Functions
    #####################################################

    # move down the canvas by n points
    # returns the new y position
    #
    def move_down(n)
      x, y = current_point
      newy = y + n
      move_to(x, newy)
      newy
    end

    # move up the canvas by n points
    # returns the new y position
    #
    def move_up(n)
      x, y = current_point
      newy = y - n
      move_to(x, newy)
      newy
    end

    # move left across the canvas by n points
    # returns the new x position
    #
    def move_left(n)
      x, y = current_point
      newx = x - n
      move_to(newx, y)
      newx
    end

    # move right across the canvas by n points
    # returns the new x position
    #
    def move_right(n)
      x, y = current_point
      newx = x + n
      move_to(newx, y)
      newx
    end

    # Moves down the document and then executes a block.
    #
    #   pdf.text "some text"
    #   pdf.pad_top(100) do
    #     pdf.text "This is 100 points below the previous line of text"
    #   end
    #   pdf.text "This text appears right below the previous line of text"
    #
    def pad_top(n)
      move_down n
      yield
    end

    # Executes a block then moves down the document
    #
    #   pdf.text "some text"
    #   pdf.pad_bottom(100) do
    #     pdf.text "This text appears right below the previous line of text"
    #   end
    #   pdf.text "This is 100 points below the previous line of text"
    #
    def pad_bottom(n)
      yield
      move_down n
    end

    # Moves down the document by y, executes a block, then moves down the
    # document by y again.
    #
    #   pdf.text "some text"
    #   pdf.pad(100) do
    #     pdf.text "This is 100 points below the previous line of text"
    #   end
    #   pdf.text "This is 100 points below the previous line of text"
    #
    def pad(n)
      if block_given?
        move_down n
        yield
        move_down n
      else
        move_down n
      end
    end

    # Moves right across the document by n, executes a block, then moves back
    # left by the same amount
    #
    #   pdf.text "some text"
    #   pdf.indent(50) do
    #     pdf.text "This starts 50 points right the previous line of text"
    #   end
    #   pdf.text "This starts in line with the first line of text"
    #
    # If no block is provided, operates just like move_right.
    #
    def indent(n)
      if block_given?
        move_right n
        yield
        move_left n
      else
        move_right n
      end
    end

    # move the cursor to an arbitary position on the current page
    def move_to(x,y)
      @context.move_to(x,y)
    end

    # reset the cursor by moving it to the top left of the useable section of the page
    def reset_cursor
      @context.move_to(margin_left,margin_top)
    end

    # returns true if the PDF has already been rendered, false if it hasn't.
    # Due to limitations of the underlying libraries, content cannot be
    # added to a PDF once it has been rendered.
    #
    def finished?
      @output.seek(@output.size - 6)
      bytes = @output.read(6)
      bytes == "%%EOF\n" ? true : false
    end

    # add the same elements to multiple pages. Useful for adding items like headers, footers and
    # watermarks.
    #
    # There is a single block parameter that is a proxy to the current PDF::Wrapper object that
    # disallows start_new_page calls. Every other method from PDF::Wrapper is considered valid.
    #
    # arguments:
    # <tt>spec</tt>::     Which pages to add the items to. :all, :odd, :even, a range, an Array of numbers or an number
    #
    # To add text to every page that mentions the page number
    #   pdf.repeating_element(:all) do |page|
    #     page.text("Page #{page.page}!", :left => page.margin_left, :top => page.margin_top, :font_size => 18)
    #   end
    #
    # To add a circle to the middle of every page
    #   pdf.repeating_element(:all) do |page|
    #     page.circle(page.absolute_x_middle, page.absolute_y_middle, 100)
    #   end
    #
    def repeating_element(spec = :all, &block)
      call_repeating_element(spec, block)

      # store it so we can add it to future pages
      @repeating << {:spec => spec, :block => block}
    end

    # move to the next page
    #
    # options:
    # <tt>:paper</tt>::   The paper size to use (default: same as the previous page)
    # <tt>:orientation</tt>::   :portrait or :landscape (default: same as the previous page)
    # <tt>:pageno</tt>::    If specified, the current page number will be set to that. By default, the page number will just increment.
    # <tt>:template</tt>::  The path to an image file. If specified, the new page will use the specified image as a template. The page will be sized to match the template size
    #
    def start_new_page(opts = {})
      opts.assert_valid_keys(:paper, :orientation, :pageno, :template)

      set_dimensions(opts[:orientation], opts[:paper])

      @context.show_page

      if opts[:template]
        w, h = image_dimensions(opts[:template])
        @surface.set_size(w, h)
        image(opts[:template], :left => 0, :top => 0)
      else
        @surface.set_size(@page_width, @page_height)
      end

      # reset or increment the page counter
      if opts[:pageno]
        @page = opts[:pageno].to_i
      else
        @page += 1
      end

      # move the cursor to the top left of our page body
      reset_cursor

      # apply the appropriate repeating elements to the new page
      @repeating.each do |repeat|
        call_repeating_element(repeat[:spec], repeat[:block])
      end
    end

    private

    def set_dimensions(orientation, paper)
      # use the defaults if none were provided
      orientation ||= @orientation
      paper       ||= @paper

      # safety check
      orientation = orientation.to_sym
      paper = paper.to_sym

      raise ArgumentError, "Unrecognised paper size (#{paper})" if PAGE_SIZES[paper].nil?

      # set page dimensions
      if orientation.eql?(:portrait)
        @page_width = PAGE_SIZES[paper][0]
        @page_height = PAGE_SIZES[paper][1]
      elsif orientation.eql?(:landscape)
        @page_width = PAGE_SIZES[paper][1]
        @page_height = PAGE_SIZES[paper][0]
      else
        raise ArgumentError, "Invalid orientation"
      end

      # make the new values the defaults
      @orientation = orientation
      @paper = paper
    end

    def finish
      # finalise the document
      @context.show_page
      @context.target.finish
    rescue Cairo::SurfaceFinishedError
      # do nothing, we're happy that the surfaced has been finished
    end

    # runs the code in block, passing it a hash of options that might be
    # required
    def call_repeating_element(spec, block)
      if spec == :all ||
         (spec == :even && (page % 2) == 0) ||
         (spec == :odd && (page % 2) == 1) ||
         (spec.class == Range && spec.include?(page)) ||
         (spec.class == Array && spec.include?(page)) ||
         (spec.respond_to?(:to_i) && spec.to_i == page)

        @context.save do
          # add it to the current page
          block.call PDF::Wrapper::Page.new(self)
        end
      end
    end

    def default_positioning_options
      # TODO: use these defaults in appropriate places
      x, y = current_point
      { :left   => x,
        :top    => y,
        :width  => points_to_right_margin(x),
        :height => points_to_bottom_margin(y)
      }
    end

    # save and restore the cursor position around a block
    def save_coords(&block)
      origx, origy = current_point
      yield
      move_to(origx, origy)
    end

    # save and restore the cursor position and graphics state around a block
    def save_coords_and_state(&block)
      origx, origy = current_point
      @context.save do
        yield
      end
      move_to(origx, origy)
    end

    def translate_color(c)
      # the follow line converts a color definition from various formats (hex, symbol, etc)
      # into a 4 item array. This is normally handled within cairo itself, however when
      # Cairo and Poppler are both loaded, it breaks.
      Cairo::Color.parse(c).to_rgb.to_a
    end

    def user_x_to_device_x(x)
      @context.user_to_device(x, 0).first.abs
    end

    def user_y_to_device_y(y)
      @context.user_to_device(0, y).last.abs
    end

    def device_x_to_user_x(x)
      @context.device_to_user(x, 0).first.abs
    end

    def device_y_to_user_y(y)
      @context.device_to_user(0, y).last.abs
    end

    # test to see if the specified colour is a a valid cairo color
    #
    # for info on what is valid, see the comments for default_color
    def validate_color(c)
      c = translate_color(c)
      @context.save
      # catch and reraise an exception to keep stack traces readable and clear
      begin
        raise ArgumentError unless c.kind_of?(Array)
        raise ArgumentError if c.size != 3 && c.size != 4
        @context.set_source_rgba(c)
      rescue ArgumentError
        c.kind_of?(Array) ? str = "[#{c.join(",")}]" : str = c.to_s
        raise ArgumentError, "#{str} is not a valid color definition"
      ensure
        @context.restore
      end
      return true
    end
  end
end
