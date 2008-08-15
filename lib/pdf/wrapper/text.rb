module PDF
  class Wrapper

    # Change the default font size
    #
    # If no block is provided, the change is permanent. If a block
    # is provided, the change will revert at the end of the block
    #
    # Permanant change:
    #
    #   pdf.font_size 10
    #
    # Temporary change:
    #
    #   pdf.font_size 20
    #   pdf.text "This text is size 20"
    #   pdf.font_size(10) do
    #     pdf.text "This text is size 20"
    #   end
    #   pdf.text "This text is size 20"
    #
    def font_size(size)
      new_size = size.to_i
      raise ArgumentError, 'font size must be > 0' if new_size <= 0

      if block_given?
        orig_size = @default_font_size
        @default_font_size = new_size
        yield
        @default_font_size = orig_size
      else
        @default_font_size = new_size
      end
    end
    alias font_size= font_size

    # change the default font to write with
    def font(fontname, style = nil, weight = nil)
      @default_font = fontname
      @default_font_style = style unless style.nil?
      @default_font_weight = weight unless weight.nil?
    end

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
    # <tt>:radius</tt>:: Give the border around the cell rounded corners. Implies :border => "tblr"
    def cell(str, x, y, w, h, opts={})
      # TODO: add a wrap option so wrapping can be disabled
      # TODO: add an option for vertical alignment
      # TODO: allow cell contents to be defined as a block, like link_to in EDGE rails

      options = default_text_options
      options.merge!({:border => "tblr", :border_width => @default_line_width, :border_color => :black,  :fill_color => nil, :padding => 3, :radius => nil})
      options.merge!(opts)
      options.assert_valid_keys(default_text_options.keys + [:width, :border, :border_width, :border_color, :fill_color, :padding, :radius])

      # apply padding
      textw = w - (options[:padding] * 2)
      texth = h - (options[:padding] * 2)

      # if the user wants a rounded rectangle, we'll draw the border with a rectangle instead
      # of 4 lines
      options[:border] = nil if options[:radius]

      # normalise the border
      options[:border] = "" unless options[:border]
      options[:border].downcase!

      save_coords do
        translate(x, y) do
          # draw a border around the cell
          if options[:radius]
            rectangle(0,0,w,h, :radius => options[:radius], :color => options[:border_color], :fill_color => options[:fill_color], :line_width => options[:border_width])
          else
            rectangle(0,0,w,h, :color => options[:fill_color], :fill_color => options[:fill_color])     if options[:fill_color]
            line(0,0,w,0,      :color => options[:border_color], :line_width => options[:border_width]) if options[:border].include?("t")
            line(0,h,w,h,      :color => options[:border_color], :line_width => options[:border_width]) if options[:border].include?("b")
            line(0,0,0,h,      :color => options[:border_color], :line_width => options[:border_width]) if options[:border].include?("l")
            line(w,0,w,h,      :color => options[:border_color], :line_width => options[:border_width]) if options[:border].include?("r")
          end

          layout = build_pango_layout(str.to_s, textw, options)

          color(options[:color]) if options[:color]

          # draw the context on our cairo layout
          render_layout(layout, options[:padding], options[:padding], texth)
        end

      end
    end

    # Write text to the page
    #
    # By default the text will be rendered using all the space within the margins and using
    # the default font styling set by font(), font_size, etc
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
    # <tt>:wrap</tt>::  The wrapping technique to use if required. Use :word, :char or :wordchar. Default is :wordchar
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
    # Italics: "Some of this text is in <i>italics</i>."
    # Strikethrough: "My name is <s>Bob</s>James."
    # Monospace Font: "Code:\n<tt>puts 1</tt>."
    #
    # For more advanced control, use span tags
    #
    # Big and Bold: Some of this text is <span weight="bold" font_desc="20">bold</span>.
    # Stretched: Some of this text is <span stretch="extraexpanded">funny looking</span>.
    #
    def text(str, opts={})
      # TODO: add converters from various markup languages to pango markup. (markdown, textile, etc)
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

      color(options[:color]) if options[:color]

      # draw the context on our cairo layout
      y = render_layout(layout, options[:left], options[:top])

      move_to(options[:left], y)
    end

    # Returns the amount of vertical space needed to display the supplied text at the requested width
    # opts is an options hash that specifies various attributes of the text. See the text function for more information.
    def text_height(str, width, opts = {})
      options = default_text_options.merge(opts)
      options.assert_valid_keys(default_text_options.keys)
      options[:width] = width || body_width

      layout = build_pango_layout(str.to_s, options[:width], options)
      width, height = layout.size

      return height / Pango::SCALE
    end

    # Returns the amount of horizontal space needed to display the supplied text with the requested options
    # opts is an options hash that specifies various attributes of the text. See the text function for more information.
    # The text is assumed to not wrap.
    def text_width(str, opts = {})
      options = default_text_options.merge(opts)
      options.assert_valid_keys(default_text_options.keys)

      layout = build_pango_layout(str.to_s, -1, options)
      width, height = layout.size

      return width / Pango::SCALE
    end

    private

    # takes a string and a range of options and creates a pango layout for us. Pango
    # does all the hard work of calculating text layout, wrapping, fonts, sizes,
    # direction and more. Thank $diety.
    #
    # The string should be encoded using utf-8. If you get unexpected characters in the 
    # rendered output, check the string encoding. Under Ruby 1.9 compatible VMs, any
    # non utf-8 strings will be automatically converted if possible.
    #
    # The layout will be constrained to the requested width, but has no maximum height. It
    # is up to some other part of the code to decide how much of the layout should actually
    # be rendered to the document, when page breaks should be inserted, etc. To specify no
    # wrapping, set width to nil. This will result in a single line layout that is as wide
    # as it needs to be to fit the entire string.
    #
    # options:
    # <tt>:markup</tt>::    The markup language of the string. See Wrapper#text for more information
    # <tt>:spacing</tt>::   The spacing between lines. See Wrapper#text for more information
    # <tt>:alignment</tt>:: The alignment of the text. See Wrapper#text for more information
    # <tt>:justify</tt>::   Should spacing between words be tweaked so each edge of the line touches 
    #                       the edge of the layout. See Wrapper#text for more information
    # <tt>:font</tt>::      The font to use. See Wrapper#text for more information
    # <tt>:font_size</tt>:: The font size to use. See Wrapper#text for more information
    # <tt>:wrap</tt>::      The wrap technique to use. See Wrapper#text for more information
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
      if w.nil? || w < 0
        layout.width = -1
      else
        # width is specified in user points
        layout.width = w * Pango::SCALE
      end
      # spacing is specified in user points
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

      # set the wrapping technique text of the layout
      if options[:wrap].eql?(:word)
        layout.wrap = Pango::Layout::WRAP_WORD
      elsif options[:wrap].eql?(:char)
        layout.wrap = Pango::Layout::WRAP_CHAR
      elsif options[:wrap].eql?(:wordchar)
        layout.wrap = Pango::Layout::WRAP_WORD_CHAR
      else
        raise ArgumentError, "Invalid wrap technique requested"
      end

      # justify the text if need be - only works in pango >= 1.17
      layout.justify = true if options[:justify]

      # setup the font that will be used to render the text
      fdesc = Pango::FontDescription.new(options[:font])
      # font size should be specified in device points for simplicity's sake.
      fdesc.size = options[:font_size] * Pango::SCALE
      layout.font_description = fdesc
      @context.update_pango_layout(layout)

      return layout
    end

    def default_text_options
      { :font => @default_font,
        :font_size => @default_font_size,
        :alignment => :left,
        :wrap => :wordchar,
        :justify => false,
        :spacing => 0,
        :color => nil,
        :markup => nil
      }
    end

    # renders a pango layout onto our main context
    # based on a function of the same name found in the text2.rb sample file
    # distributed with rcairo - it's still black magic to me and has a few edge
    # cases where it doesn't work too well. Needs to be improved.
    #
    # If h is specified, lines of text will be rendered up to that height, and 
    # the rest will be ignored. 
    #
    # If h is nil, lines will be rendered until the bottom margin is hit, then
    # a new page will be started and lines will continue being rendered at the
    # top of the new page.
    def render_layout(layout, x, y, h = nil)
      # we can't use context.show_pango_layout, as that won't start
      # a new page if the layout hits the bottom margin. Instead,
      # we iterate over each line of text in the layout and add it to
      # the canvas, page breaking as necessary

      offset = 0
      baseline = 0
      spacing = layout.spacing / Pango::SCALE

      iter = layout.iter
      loop do
        line = iter.line
        ink_rect, logical_rect = iter.line_extents

        # calculate the relative starting co-ords of this line
        baseline = iter.baseline / Pango::SCALE
        linex = logical_rect.x / Pango::SCALE

        if h && baseline - offset >= h
          # the user doesn't want us to continue on the next page, so
          # stop adding lines to the canvas
          break
        elsif h.nil? && (y + baseline - offset + spacing) >= self.absolute_bottom_margin
          # create a new page and we can continue adding text
          offset = baseline
          start_new_page
          y = self.y
        end

        # move to the start of this line
        @context.move_to(x + linex, y + baseline - offset + spacing)

        # draw the line on the canvas
        @context.show_pango_layout_line(line)

        break unless iter.next_line!
      end

      width, height = layout.size

      # return the y co-ord we finished on
      return y + (height / Pango::SCALE) - offset + spacing
    end

  end
end
