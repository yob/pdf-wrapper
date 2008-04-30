# coding: utf-8

require 'stringio'
require 'pdf/core'

# try to load cairo from the standard places, but don't worry if it fails,
# we'll try to find it via rubygems
begin
  require 'cairo'
rescue LoadError
    begin
      require 'rubygems'
      gem 'cairo', '>=1.5'
      require 'cairo'
    rescue Gem::LoadError
      raise LoadError, "Could not find the ruby cairo bindings in the standard locations or via rubygems. Check to ensure they're installed correctly"
    rescue LoadError
      raise LoadError, "Could not load rubygems"
    end
end

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
  #   pdf.default_font("Monospace")
  #   pdf.text "Hello World", :font => "Sans Serif", :font_size => 18
  #   pdf.text "Pretend this is a code sample"
  #   puts pdf.render
  class Wrapper

    attr_reader :margin_left, :margin_right, :margin_top, :margin_bottom
    attr_reader :page_width, :page_height, :page

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

      # ensure we have recentish cairo bindings
      raise "Ruby Cairo bindings version #{Cairo::BINDINGS_VERSION.join(".")} is too low. At least 1.5 is required" if Cairo::BINDINGS_VERSION.to_s < "150"

      options = {:paper => :A4,
                  :orientation => :portrait,
                  :background_color => :white
                 }
      options.merge!(opts)

      # test for invalid options
      options.assert_valid_keys(:paper, :orientation, :background_color, :margin_left, :margin_right, :margin_top, :margin_bottom, :template)
      options[:paper] = options[:paper].to_sym
      raise ArgumentError, "Invalid paper option" unless PAGE_SIZES.include?(options[:paper])

      # set page dimensions
      if options[:orientation].eql?(:portrait)
        @page_width = PAGE_SIZES[options[:paper]][0]
        @page_height = PAGE_SIZES[options[:paper]][1]
      elsif options[:orientation].eql?(:landscape)
        @page_width = PAGE_SIZES[options[:paper]][1]
        @page_height = PAGE_SIZES[options[:paper]][0]
      else
        raise ArgumentError, "Invalid orientation"
      end

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
      set_color(options[:background_color])
      @context.paint

      # set a default drawing colour and font style
      default_color(:black)
      default_line_width(2.0)
      default_font("Sans Serif")
      default_font_size(16)

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
      @margin_left
    end

    # Returns the x value of the right margin
    # The top left corner of the page is (0,0)
    def absolute_right_margin
      @page_width - @margin_right
    end

    # Returns the y value of the top margin
    # The top left corner of the page is (0,0)
    def absolute_top_margin
      @margin_top
    end

    # Returns the y value of the bottom margin
    # The top left corner of the page is (0,0)
    def absolute_bottom_margin
      @page_height - @margin_bottom
    end

    # Returns the x at the middle of the page
    def absolute_x_middle
      @page_width / 2
    end

    # Returns the y at the middle of the page
    def absolute_y_middle
      @page_height / 2
    end

    # Returns the width of the usable part of the page (between the side margins)
    def body_width
      @page_width - @margin_left - @margin_right
    end

    # Returns the height of the usable part of the page (between the top and bottom margins)
    def body_height
      @page_height - @margin_top - @margin_bottom
    end

    # Returns the x coordinate of the middle part of the usable space between the margins
    def margin_x_middle
      @margin_left + (body_width / 2)
    end

    # Returns the y coordinate of the middle part of the usable space between the margins
    def margin_y_middle
      @margin_top + (body_height / 2)
    end

    # return the current position of the cursor
    # returns 2 values - x,y
    def current_point
      return @context.current_point
    end

    # return the number of points from  starty to the bottom border
    def points_to_bottom_margin(starty)
      absolute_bottom_margin - starty
    end

    # return the number of points from  startx to the right border
    def points_to_right_margin(startx)
      absolute_right_margin - startx
    end

    #####################################################
    # Functions relating to working with text
    #####################################################

    # change the default font size
    def default_font_size(size)
      #@context.set_font_size(size.to_i)
      @default_font_size = size.to_i unless size.nil?
    end
    alias default_font_size= default_font_size
    alias font_size default_font_size          # PDF::Writer compatibility

    # change the default font to write with
    def default_font(fontname, style = nil, weight = nil)
      #@context.select_font_face(fontname, slant, bold)
      @default_font = fontname
      @default_font_style = style unless style.nil?
      @default_font_weight = weight unless weight.nil?
    end
    alias default_font= default_font
    alias select_font default_font   # PDF::Writer compatibility

    # change the default colour used to draw on the canvas
    #
    # Parameters:
    # <tt>c</tt>::  either a colour symbol recognised by rcairo (:red, :blue, :black, etc) or
    #               an array with 3-4 integer elements. The first 3 numbers are red, green and
    #               blue (0-255). The optional 4th number is the alpha channel and should be
    #               between 0 and 1. See the API docs at http://cairo.rubyforge.org/ for a list
    #               of predefined colours
    def default_color(c)
      c = translate_color(c)
      validate_color(c)
      @default_color = c
    end
    alias default_color= default_color
    alias stroke_color default_color    # PDF::Writer compatibility

    # change the default line width used to draw stroke on the canvas
    #
    # Parameters:
    # <tt>f</tt>:: float value of stroke width from 0.01 to 255
    def default_line_width(f)
      @default_line_width = f
    end
    alias default_line_width= default_line_width

    # add text to the page, bounded by a box with dimensions HxW, with it's top left corner
    # at x,y. Any text that doesn't fit it the box will be silently dropped.
    #
    # In addition to the standard text style options (see the documentation for text()), cell() supports
    # the following options:
    #
    # <tt>:border</tt>::   Which sides of the cell should have a border? A string with any combination the letters tblr (top, bottom, left, right). Nil for no border, defaults to all sides.
    # <tt>:border_width</tt>::  How wide should the border be?
    # <tt>:border_color</tt>::  What color should the border be?
    # <tt>:fill_color</tt>::  A background color for the cell. Defaults to none.
    # <tt>:padding</tt>::  The number of points to leave between the inside of the border and text. Defaults to 3.
    def cell(str, x, y, w, h, opts={})
      # TODO: add support for pango markup (see http://ruby-gnome2.sourceforge.jp/hiki.cgi?pango-markup)
      # TODO: add a wrap option so wrapping can be disabled
      # TODO: handle a single word that is too long for the width
      # TODO: add an option to draw a border with rounded corners

      options = default_text_options
      options.merge!({:border => "tblr", :border_width => @default_line_width, :border_color => :black,  :fill_color => nil, :padding => 3})
      options.merge!(opts)
      options.assert_valid_keys(default_text_options.keys + [:width, :border, :border_width, :border_color, :fill_color, :padding])

      # apply padding
      textw = w - (options[:padding] * 2)
      texth = h - (options[:padding] * 2)
      textx = x + options[:padding]
      texty = y + options[:padding]

      options[:border] = "" unless options[:border]
      options[:border].downcase!

      # save the cursor position so we can restore it at the end
      origx, origy = current_point

      # TODO: raise an exception if the box coords or dimensions will place it off the canvas
      rectangle(x,y,w,h, :color => options[:fill_color], :fill_color => options[:fill_color]) if options[:fill_color]
      layout = build_pango_layout(str.to_s, textw, options)

      set_color(options[:color])

      # draw the context on our cairo layout
      render_layout(layout, textx, texty, texth, :auto_new_page => false)

      # draw a border around the cell
      line(x,y,x+w,y, :color => options[:border_color], :line_width => options[:border_width])     if options[:border].include?("t")
      line(x,y+h,x+w,y+h, :color => options[:border_color], :line_width => options[:border_width]) if options[:border].include?("b")
      line(x,y,x,y+h, :color => options[:border_color], :line_width => options[:border_width])     if options[:border].include?("l")
      line(x+w,y,x+w,y+h, :color => options[:border_color], :line_width => options[:border_width]) if options[:border].include?("r")

      # restore the cursor position
      move_to(origx, origy)
    end

    # draws a basic table onto the page
    #
    # <tt>data</tt>:: a 2d array with the data for the columns. The first row will be treated as the headings
    #
    # In addition to the standard text style options (see the documentation for text), table supports
    # the following options:
    #
    # <tt>:left</tt>::   The x co-ordinate of the left-hand side of the table. Defaults to the left margin
    # <tt>:top</tt>::   The y co-ordinate of the top of the text. Defaults to the top margin
    # <tt>:width</tt>::   The width of the table. Defaults to the width of the page body
    def table(data, opts = {})
      # TODO: instead of accepting the data, use a XHTML table string?
      # TODO: handle overflowing to a new page
      # TODO: add a way to display borders

      x, y = current_point
      options = default_text_options.merge!({:left => x,
                                             :top => y
                                            })
      options.merge!(opts)
      options.assert_valid_keys(default_text_options.keys + default_positioning_options.keys)
      options[:width] = body_width - options[:left] unless options[:width]

      # move to the start of our table (the top left)
      x = options[:left]
      y = options[:top]
      move_to(x,y)

      # all columns will have the same width at this stage
      cell_width = options[:width] / data.first.size

      # draw the header cells
      y = draw_table_row(data.shift, cell_width, options)
      x = options[:left]
      move_to(x,y)

      # draw the data cells
      data.each do |row|
        y = draw_table_row(row, cell_width, options)
        x = options[:left]
        move_to(x,y)
      end
    end

    # Write text to the page
    #
    # By default the text will be rendered using all the space within the margins and using
    # the default font styling set by default_font(), default_font_size, etc
    #
    # There is no way to place a bottom bound (or height) onto the text. Text will wrap as
    # necessary and take all the room it needs. For finer grained control of text boxes, see the
    # cell method.
    #
    # To override all these defaults, use the options hash
    #
    # Positioning Options:
    #
    # <tt>:left</tt>::   The x co-ordinate of the left-hand side of the text.
    # <tt>:top</tt>::   The y co-ordinate of the top of the text.
    # <tt>:width</tt>::   The width of the text to wrap at
    #
    # Text Style Options:
    #
    # <tt>:font</tt>::   The font family to use as a string
    # <tt>:font_size</tt>::   The size of the font in points
    # <tt>:alignment</tt>::   Align the text along the left, right or centre. Use :left, :right, :center
    # <tt>:justify</tt>::   Justify the text so it exapnds to fill the entire width of each line. Note that this only works in pango >= 1.17
    # <tt>:spacing</tt>::  Space between lines in PDF points
    # <tt>:markup</tt>::  Interpret the text as a markup language. Default is nil (none).
    #
    # = Markup
    # 
    # If the markup option is specified, the text can be modified in various ways. At this stage
    # the only markup syntax implemented is :pango.
    #
    # == Pango Markup
    #
    # Full details on the Pango markup language are avaialble at http://ruby-gnome2.sourceforge.jp/hiki.cgi?pango-markup
    #
    # The format is vaguely XML-like.
    #
    # Bold: "Some of this text is <b>bold</b>."
    # Italics: "Some of this text is in <b>italics</b>."
    # Strikethrough: "My name is <s>Bob</s>James."
    # Monospace Font: "Code:\n<tt>puts 1</tt>."
    #
    # For more advanced control, use span tags
    #
    # Big and Bold: Some of this text is <span weight="bold" font_desc="20">bold</span>.
    # Stretched: Some of this text is <span stretch="extraexpanded">funny looking</span>.
    def text(str, opts={})
      # TODO: add converters from various markup languages to pango markup. (bluecloth, redcloth, markdown, textile, etc)
      # TODO: add a wrap option so wrapping can be disabled
      #
      # the non pango way to add text to the cairo context, not particularly useful for
      # PDF generation as it doesn't support wrapping text or other advanced layout features
      # and I really don't feel like re-implementing all that
      # @context.show_text(str)

      # the "pango way"
      x, y = current_point
      options = default_text_options.merge!({:left => x, :top => y})
      options.merge!(opts)
      options.assert_valid_keys(default_text_options.keys + default_positioning_options.keys)

      # if the user hasn't specified a width, make the text wrap on the right margin
      options[:width] = absolute_right_margin - options[:left] if options[:width].nil?

      layout = build_pango_layout(str.to_s, options[:width], options)

      set_color(options[:color])

      # draw the context on our cairo layout
      y = render_layout(layout, options[:left], options[:top], points_to_bottom_margin(options[:top]), :auto_new_page => true)

      move_to(options[:left], y + 5)
    end

    # Returns the amount of vertical space needed to display the supplied text at the requested width
    # opts is an options hash that specifies various attributes of the text. See the text function for more information.
    def text_height(str, width, opts = {})
      options = default_text_options.merge!(opts)
      options[:width] = width || body_width
      options.assert_valid_keys(default_text_options.keys + default_positioning_options.keys)

      layout = build_pango_layout(str.to_s, options[:width], options)
      width, height = layout.size

      return height / Pango::SCALE
    end

    # Returns the amount of horizontal space needed to display the supplied text with the requested options
    # opts is an options hash that specifies various attributes of the text. See the text function for more information.
    # The text is assumed to not wrap.
    def text_width(str, opts = {})
      options = default_text_options.merge!(opts)
      options.assert_valid_keys(default_text_options.keys)

      layout = build_pango_layout(str.to_s, -1, options)
      width, height = layout.size

      return width / Pango::SCALE
    end

    #####################################################
    # Functions relating to working with graphics
    #####################################################

    # draw a circle with radius r and a centre point at (x,y).
    # Parameters:
    # <tt>:x</tt>::   The x co-ordinate of the circle centre.
    # <tt>:y</tt>::   The y co-ordinate of the circle centre.
    # <tt>:r</tt>::   The radius of the circle
    #
    # Options:
    # <tt>:color</tt>::   The colour of the circle outline
    # <tt>:line_width</tt>::   The width of outline. Defaults to 2.0
    # <tt>:fill_color</tt>::   The colour to fill the circle with. Defaults to nil (no fill)
    def circle(x, y, r, opts = {})
      options = {:color => @default_color,
                 :line_width => @default_line_width,
                 :fill_color => nil
                 }
      options.merge!(opts)
      options.assert_valid_keys(:color, :line_width, :fill_color)

      # save the cursor position so we can restore it at the end
      origx, origy = current_point

      move_to(x + r, y)

      # if the circle should be filled in
      if options[:fill_color]
        set_color(options[:fill_color])
        @context.circle(x, y, r).fill
      end

      set_color(options[:color])
      @context.set_line_width(options[:line_width])
      @context.circle(x, y, r).stroke

      # restore the cursor position
      move_to(origx, origy)
    end

    # draw a line from x1,y1 to x2,y2
    #
    # Options:
    # <tt>:color</tt>::   The colour of the line
    # <tt>:line_width</tt>::   The width of line. Defaults its 2.0
    def line(x0, y0, x1, y1, opts = {})
      options = {:color => @default_color, :line_width => @default_line_width }
      options.merge!(opts)
      options.assert_valid_keys(:color, :line_width)

      # save the cursor position so we can restore it at the end
      origx, origy = current_point

      set_color(options[:color])
      @context.set_line_width(options[:line_width])
      move_to(x0,y0)
      @context.line_to(x1,y1).stroke

      # restore the cursor position
      move_to(origx, origy)
    end

    # Adds a cubic Bezier spline to the path from the  (x0, y0) to position (x3, y3)
    # in user-space coordinates, using (x1, y1) and (x2, y2) as the control points.
    # Options:
    # <tt>:color</tt>::   The colour of the line
    # <tt>:line_width</tt>::   The width of line. Defaults to 2.0
    def curve(x0, y0, x1, y1, x2, y2, x3, y3, opts = {})
      options = {:color => @default_color, :line_width => @default_line_width }
      options.merge!(opts)
      options.assert_valid_keys(:color, :line_width)
      origx, origy = current_point

      set_color(options[:color])
      @context.set_line_width(options[:line_width])
      move_to(x0,y0)
      @context.curve_to(x1, y1, x2, y2, x3, y3).stroke

      # restore the cursor position
      move_to(origx, origy)
    end


    # draw a rectangle starting at x,y with w,h dimensions.
    # Parameters:
    # <tt>:x</tt>::   The x co-ordinate of the top left of the rectangle.
    # <tt>:y</tt>::   The y co-ordinate of the top left of the rectangle.
    # <tt>:w</tt>::   The width of the rectangle
    # <tt>:h</tt>::   The height of the rectangle
    #
    # Options:
    # <tt>:color</tt>::   The colour of the rectangle outline
    # <tt>:line_width</tt>::   The width of outline. Defaults to 2.0
    # <tt>:fill_color</tt>::   The colour to fill the rectangle with. Defaults to nil (no fill)
    def rectangle(x, y, w, h, opts = {})
      options = {:color => @default_color,
                 :line_width => @default_line_width,
                 :fill_color => nil
                 }
      options.merge!(opts)
      options.assert_valid_keys(:color, :line_width, :fill_color)

      # save the cursor position so we can restore it at the end
      origx, origy = current_point

      # if the rectangle should be filled in
      if options[:fill_color]
        set_color(options[:fill_color])
        @context.rectangle(x, y, w, h).fill
      end

      set_color(options[:color])
      @context.set_line_width(options[:line_width])
      @context.rectangle(x, y, w, h).stroke

      # restore the cursor position
      move_to(origx, origy)
    end

    # draw a rounded rectangle starting at x,y with w,h dimensions.
    # Parameters:
    # <tt>:x</tt>::   The x co-ordinate of the top left of the rectangle.
    # <tt>:y</tt>::   The y co-ordinate of the top left of the rectangle.
    # <tt>:w</tt>::   The width of the rectangle
    # <tt>:h</tt>::   The height of the rectangle
    # <tt>:r</tt>::   The size of the rounded corners
    #
    # Options:
    # <tt>:color</tt>::   The colour of the rectangle outline
    # <tt>:line_width</tt>::   The width of outline. Defaults to 2.0
    # <tt>:fill_color</tt>::   The colour to fill the rectangle with. Defaults to nil (no fill)
    def rounded_rectangle(x, y, w, h, r, opts = {})
      options = {:color => @default_color,
                 :line_width => @default_line_width,
                 :fill_color => nil
                 }
      options.merge!(opts)
      options.assert_valid_keys(:color, :fill_color, :line_width)

      raise ArgumentError, "Argument r must be less than both w and h arguments" if r >= w || r >= h

      # save the cursor position so we can restore it at the end
      origx, origy = current_point

      # if the rectangle should be filled in
      if options[:fill_color]
        set_color(options[:fill_color])
        @context.rounded_rectangle(x, y, w, h, r).fill
      end

      set_color(options[:color])
      @context.set_line_width(options[:line_width])
      @context.rounded_rectangle(x, y, w, h, r).stroke

      # restore the cursor position
      move_to(origx, origy)
    end

    #####################################################
    # Functions relating to working with images
    #####################################################

    # add an image to the page - a wide range of image formats are supported,
    # including svg, jpg, png and gif. PDF images are also supported - an attempt
    # to add a multipage PDF will result in only the first page appearing in the
    # new document.
    #
    # supported options:
    # <tt>:left</tt>::     The x co-ordinate of the left-hand side of the image.
    # <tt>:top</tt>::      The y co-ordinate of the top of the image.
    # <tt>:height</tt>::   The height of the image
    # <tt>:width</tt>::    The width of the image
    # <tt>:proportional</tt>::   Boolean. Maintain image proportions when scaling. Defaults to false.
    # <tt>:padding</tt>::    Add some padding between the image and the specified box.
    #
    # left and top default to the current cursor location
    # width and height default to the size of the imported image
    # padding defaults to 0
    def image(filename, opts = {})
      # TODO: add some options for justification and padding
      raise ArgumentError, "file #{filename} not found" unless File.file?(filename)
      opts.assert_valid_keys(default_positioning_options.keys + [:padding, :proportional])

      if opts[:padding]
        opts[:left]   += opts[:padding].to_i if opts[:left]
        opts[:top]    += opts[:padding].to_i if opts[:top]
        opts[:width]  -= opts[:padding].to_i * 2 if opts[:width]
        opts[:height] -= opts[:padding].to_i * 2 if opts[:height]
      end

      case detect_image_type(filename)
      when :pdf   then draw_pdf filename, opts
      when :png   then draw_png filename, opts
      when :svg   then draw_svg filename, opts
      else
        begin
          draw_pixbuf filename, opts
        rescue Gdk::PixbufError
          raise ArgumentError, "Unrecognised image format (#{filename})"
        end
      end
    end

    #####################################################
    # Functions relating to generating the final document
    #####################################################

    # render the PDF and return it as a string
    def render
      # finalise the document, then convert the StringIO object it was rendered to
      # into a string
      @context.show_page
      @context.target.finish
      return @output.string
    end

    # save the rendered PDF to a file
    def render_to_file(filename)
      # finalise the document
      @context.show_page
      @context.target.finish

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

    def pad(n)
      x, y = current_point
      move_to(x, y + n)
      y + n
    end

    # move the cursor to an arbitary position on the current page
    def move_to(x,y)
      raise ArgumentError, 'x cannot be larger than the width of the page' if x > page_width
      raise ArgumentError, 'y cannot be larger than the height of the page' if y > page_height
      @context.move_to(x,y)
    end

    # reset the cursor by moving it to the top left of the useable section of the page
    def reset_cursor
      @context.move_to(margin_left,margin_top)
    end

    # add the same elements to multiple pages. Useful for adding items like headers, footers and
    # watermarks.
    #
    # arguments:
    # <tt>spec</tt>::     Which pages to add the items to. :all, :odd, :even, a range, an Array of numbers or an number
    #
    # To add text to every page that mentions the page number
    #   pdf.repeating_element(:all) do
    #     pdf.text("Page #{pdf.page}!", :left => pdf.margin_left, :top => pdf.margin_top, :font_size => 18)
    #   end
    #
    # To add a circle to the middle of every page
    #   pdf.repeating_element(:all) do
    #     pdf.circle(pdf.absolute_x_middle, pdf.absolute_y_middle, 100)
    #   end
    def repeating_element(spec = :all, &block)
      call_repeating_element(spec, block)

      # store it so we can add it to future pages
      @repeating << {:spec => spec, :block => block}
    end

    # move to the next page
    #
    # options:
    # <tt>:pageno</tt>::    If specified, the current page number will be set to that. By default, the page number will just increment.
    # <tt>:template</tt>::  The path to an image file. If specified, the new page will use the specified image as a template. The page will be sized to match the template size
    def start_new_page(opts = {})
      opts.assert_valid_keys(:pageno, :template)

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

    def build_pango_layout(str, w, opts = {})
      options = default_text_options.merge!(opts)

      # if the user hasn't specified a width, make the layout as wide as the page body
      w = body_width if w.nil?

      # even though this is a private function, raise this error to force calling functions
      # to decide how they want to handle converting non-strings into strings for rendering
      raise ArgumentError, 'build_pango_layout must be passed a string' unless str.kind_of?(String)

      # if we're running under a M17n aware VM, ensure the string provided is UTF-8 or can be
      # converted to UTF-8
      if RUBY_VERSION >= "1.9"
        begin
          str = str.encode("UTF-8")
        rescue
          raise ArgumentError, 'Strings must be supplied with a UTF-8 encoding, or an encoding that can be converted to UTF-8'
        end
      end

      # The pango way:
      load_libpango

      # create a new Pango layout that our text will be added to
      layout = @context.create_pango_layout
      if options[:markup] == :pango
        layout.markup = str.to_s
      else
        layout.text = str.to_s
      end
      if w == -1
        layout.width = -1
      else
        layout.width = w * Pango::SCALE
      end
      layout.spacing = options[:spacing] * Pango::SCALE

      # set the alignment of the text in the layout
      if options[:alignment].eql?(:left)
        layout.alignment = Pango::Layout::ALIGN_LEFT
      elsif options[:alignment].eql?(:right)
        layout.alignment = Pango::Layout::ALIGN_RIGHT
      elsif options[:alignment].eql?(:center) || options[:alignment].eql?(:centre)
        layout.alignment = Pango::Layout::ALIGN_CENTER
      else
        raise ArgumentError, "Invalid alignment requested"
      end

      # justify the text if need be - only works in pango >= 1.17
      layout.justify = true if options[:justify]

      # setup the font that will be used to render the text
      fdesc = Pango::FontDescription.new(options[:font])
      fdesc.set_size(options[:font_size] * Pango::SCALE)
      layout.font_description = fdesc
      @context.update_pango_layout(layout)
      return layout
    end

    # runs the code in block, passing it a hash of options that might be
    # required
    def call_repeating_element(spec, block)
      # TODO: disallow start_new_page when adding a repeating element
      if spec == :all ||
         (spec == :even && (page % 2) == 0) ||
         (spec == :odd && (page % 2) == 1) ||
         (spec.class == Range && spec.include?(page)) ||
         (spec.class == Array && spec.include?(page)) ||
         (spec.respond_to?(:to_i) && spec.to_i == page)

        @context.save do
          # add it to the current page
          block.call
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

    def default_text_options
      { :font => @default_font,
        :font_size => @default_font_size,
        :color => @default_color,
        :alignment => :left,
        :justify => false,
        :spacing => 0,
        :markup => nil
      }
    end

    def detect_image_type(filename)
      # read the first Kb from the file to attempt file type detection
      f = File.new(filename)
      bytes = f.read(1024)

      # if the file is a PNG
      if bytes[1,3].eql?("PNG")
        return :png
      elsif bytes[0,3].eql?("GIF")
        return :gif
      elsif bytes[0,4].eql?("%PDF")
        return :pdf
      elsif bytes.include?("<svg")
        return :svg
      elsif bytes.include?("Exif") || bytes.include?("JFIF")
        return :jpg
      else
        return nil
      end
    end

    def calc_image_dimensions(desired_w, desired_h, actual_w, actual_h, scale = false)
      if scale
        wp = desired_w / actual_w.to_f
        hp = desired_h / actual_h.to_f

        if wp < hp
          width = actual_w * wp
          height = actual_h * wp
        else
          width = actual_w * hp
          height = actual_h * hp
        end
      else
        width = desired_w || actual_w
        height = desired_h || actual_h
      end
      return width.to_f, height.to_f
    end

    def draw_pdf(filename, opts = {})
      # based on a similar function in rabbit. Thanks Kou.
      load_libpoppler
      x, y = current_point
      page = Poppler::Document.new(filename).get_page(1)
      w, h = page.size
      width, height = calc_image_dimensions(opts[:width], opts[:height], w, h, opts[:proportional])
      @context.save do
        @context.translate(opts[:left] || x, opts[:top] || y)
        @context.scale(width / w, height / h)
        @context.render_poppler_page(page)
      end
      move_to(opts[:left] || x, (opts[:top] || y) + height)
    end

    def draw_pixbuf(filename, opts = {})
      # based on a similar function in rabbit. Thanks Kou.
      load_libpixbuf
      x, y = current_point
      pixbuf = Gdk::Pixbuf.new(filename)
      width, height = calc_image_dimensions(opts[:width], opts[:height], pixbuf.width, pixbuf.height, opts[:proportional])
      @context.save do
        @context.translate(opts[:left] || x, opts[:top] || y)
        @context.scale(width / pixbuf.width, height / pixbuf.height)
        @context.set_source_pixbuf(pixbuf, 0, 0)
        @context.paint
      end
      move_to(opts[:left] || x, (opts[:top] || y) + height)
    end

    def draw_png(filename, opts = {})
      # based on a similar function in rabbit. Thanks Kou.
      x, y = current_point
      img_surface = Cairo::ImageSurface.from_png(filename)
      width, height = calc_image_dimensions(opts[:width], opts[:height], img_surface.width, img_surface.height, opts[:proportional])
      @context.save do
        @context.translate(opts[:left] || x, opts[:top] || y)
        @context.scale(width / img_surface.width, height / img_surface.height)
        @context.set_source(img_surface, 0, 0)
        @context.paint
      end
      move_to(opts[:left] || x, (opts[:top] || y) + height)
    end

    def draw_svg(filename, opts = {})
      # based on a similar function in rabbit. Thanks Kou.
      load_librsvg
      x, y = current_point
      handle = RSVG::Handle.new_from_file(filename)
      width, height = calc_image_dimensions(opts[:width], opts[:height], handle.width, handle.height, opts[:proportional])
      @context.save do
        @context.translate(opts[:left] || x, opts[:top] || y)
        @context.scale(width / handle.width, height / handle.height)
        @context.render_rsvg_handle(handle)
        #@context.paint
      end
      move_to(opts[:left] || x, (opts[:top] || y) + height)
    end

    # adds a single table row to the canvas. Top left of the row will be at the current x,y
    # co-ordinates, so make sure they're set correctly before calling this function
    #
    # strings - array of strings. Each element of the array is a cell
    # column_widths - the width of each column. At this stage it should be an int. All columns are the same width
    # options - any options relating to text style to use. font, font_size, alignment, etc. See text() for more info.
    #
    # Returns the y co-ordinates of the bottom edge of the row, ready for the next row
    def draw_table_row(strings, column_widths, options)
      row_height = 0
      x, y = current_point

      # we run all this code twice. The first time is a dry run to calculate the
      # height of the largest cell, which determines the overall height of the row.
      # The second run through we actually draw each cell onto the canvas
      [:dry, :paint].each do |action|

        strings.each do |head|
          # TODO: provide a way for these to be overridden on a per cell basis
          opts = {
            :font      => options[:font],
            :font_size => options[:font_size],
            :color     => options[:color],
            :alignment => options[:alignment],
            :justify   => options[:justify],
            :spacing   => options[:spacing]
          }

          if action == :dry
            # calc the cell height, and set row_height if this cell is the biggest in the row
            cell_height = text_height(head, column_widths, opts)
            row_height = cell_height if cell_height > row_height
          else
            # start a new page if necesary
            if row_height > (absolute_bottom_margin - y)
              start_new_page
              y = margin_top
            end

            # add our cell, then advance x to the left edge of the next cell
            self.cell(head, x, y, column_widths, row_height, opts)
            x += column_widths
          end

        end
      end

      return y + row_height
    end

    def image_dimensions(filename)
      raise ArgumentError, "file #{filename} not found" unless File.file?(filename)

      case detect_image_type(filename)
      when :pdf   then
        load_libpoppler
        page = Poppler::Document.new(filename).get_page(1)
        return page.size
      when :png   then
        img_surface = Cairo::ImageSurface.from_png(filename)
        return img_surface.width, img_surface.height
      when :svg   then
        load_librsvg
        handle = RSVG::Handle.new_from_file(filename)
        return handle.width, handle.height
      else
        load_libpixbuf
        begin
          pixbuf = Gdk::Pixbuf.new(filename)
          return pixbuf.width, pixbuf.height
        rescue Gdk::PixbufError
          raise ArgumentError, "Unrecognised image format (#{filename})"
        end
      end
    end

    # load libpango if it isn't already loaded.
    # This will add some methods to the cairo Context class in addition to providing
    # its own classes and constants. A small amount of documentation is available at
    # http://ruby-gnome2.sourceforge.jp/fr/hiki.cgi?Cairo%3A%3AContext#Pango+related+APIs
    def load_libpango
      begin
        require 'pango' unless @context.respond_to? :create_pango_layout
      rescue LoadError
        raise LoadError, 'Ruby/Pango library not found. Visit http://ruby-gnome2.sourceforge.jp/'
      end
    end

    # load lib gdkpixbuf if it isn't already loaded.
    # This will add some methods to the cairo Context class in addition to providing
    # its own classes and constants.
    def load_libpixbuf
      begin
        require 'gdk_pixbuf2' unless @context.respond_to? :set_source_pixbuf
      rescue LoadError
        raise LoadError, 'Ruby/GdkPixbuf library not found. Visit http://ruby-gnome2.sourceforge.jp/'
      end
    end

    # load lib poppler if it isn't already loaded.
    # This will add some methods to the cairo Context class in addition to providing
    # its own classes and constants.
    def load_libpoppler
      begin
        require 'poppler' unless @context.respond_to? :render_poppler_page
      rescue LoadError
        raise LoadError, 'Ruby/Poppler library not found. Visit http://ruby-gnome2.sourceforge.jp/'
      end
    end

    # load librsvg if it isn't already loaded
    # This will add an additional method to the Cairo::Context class
    # that allows an existing SVG to be drawn directly onto it
    # There's a *little* bit of documentation at:
    # http://ruby-gnome2.sourceforge.jp/fr/hiki.cgi?Cairo%3A%3AContext#render_rsvg_handle
    def load_librsvg
      begin
        require 'rsvg2' unless @context.respond_to? :render_svg_handle
      rescue LoadError
        raise LoadError, 'Ruby/RSVG library not found. Visit http://ruby-gnome2.sourceforge.jp/'
      end
    end

    # renders a pango layout onto our main context
    # based on a function of the same name found in the text2.rb sample file
    # distributed with rcairo - it's still black magic to me and has a few edge
    # cases where it doesn't work too well. Needs to be improved.
    def render_layout(layout, x, y, h, opts = {})
      # we can't use context.show_pango_layout, as that won't start
      # a new page if the layout hits the bottom margin. Instead,
      # we iterate over each line of text in the layout and add it to
      # the canvas, page breaking as necessary
      options = {:auto_new_page => true }
      options.merge!(opts)

      offset = 0
      baseline = 0

      iter = layout.iter
      loop do
        line = iter.line
        ink_rect, logical_rect = iter.line_extents
        if y + (baseline - offset) >= (y + h)
          # our text is using the maximum amount of vertical space we want it to
          if options[:auto_new_page]
            # create a new page and we can continue adding text
            offset += baseline
            start_new_page
          else
            # the user doesn't want us to continue on the next page, so
            # stop adding lines to the canvas
            break
          end
        end

        # move to the start of the next line
        #move_to(x, y)
        baseline = iter.baseline / Pango::SCALE
        @context.move_to(x + logical_rect.x / Pango::SCALE, y + baseline - offset)

        # draw the line on the canvas
        @context.show_pango_layout_line(line)

        break unless iter.next_line!
      end

      # return the y co-ord we finished on
      return y + baseline - offset
    end

    def translate_color(c)
      # the follow line converts a color definition from various formats (hex, symbol, etc)
      # into a 4 item array. This is normally handled within cairo itself, however when
      # Cairo and Poppler are both loaded, it breaks.
      Cairo::Color.parse(c).to_rgb.to_a
    end

    # set the current drawing colour
    #
    # for info on what is valid, see the comments for default_color
    def set_color(c)
      c = translate_color(c)
      validate_color(c)
      @context.set_source_rgba(*c)
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
