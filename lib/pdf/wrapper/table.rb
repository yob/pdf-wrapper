module PDF
  class Wrapper

    # Draws a basic table of text on the page. See the documentation for a detailed description of
    # how to control the table and its appearance.
    #
    # <tt>data</tt>:: a 2d array with the data for the columns, or a PDF::Wrapper::Table object
    #
    # == Options
    #
    # The only options available when rendering a table are those relating to its size and location.
    # All other options that relate to the content of the table and how it looks should be configured
    # on the PDF::Wrapper::Table object that is passed into this function.
    #
    # <tt>:left</tt>::   The x co-ordinate of the left-hand side of the table. Defaults to the current cursor location
    # <tt>:top</tt>::   The y co-ordinate of the top of the text. Defaults to the current cursor location
    # <tt>:width</tt>::   The width of the table. Defaults to the distance from the left of the table to the right margin
    def table(data, opts = {})
      # TODO: add support for a table footer
      #       - repeating each page, or just at the bottom? 
      #       - if it repeats, should it be different on each page? ie. a sum of that pages rows, etc.
      # TODO: maybe support for multiple data sets with group headers/footers. useful for subtotals, etc

      x, y = current_point
      options = {:left => x, :top => y }
      options.merge!(opts)
      options.assert_valid_keys(default_positioning_options.keys)

      if data.kind_of?(::PDF::Wrapper::Table)
        t = data
      else
        t = ::PDF::Wrapper::Table.new do |table|
          table.data = data
        end
      end

      t.width = options[:width] || points_to_right_margin(options[:left])
      calc_table_dimensions t

      # move to the start of our table (the top left)
      move_to(options[:left], options[:top])

      # draw the header cells
      draw_table_headers(t) if t.headers && (t.show_headers == :page || t.show_headers == :once)

      x, y = current_point

      # loop over each row in the table
      t.cells.each_with_index do |row, row_idx|

        # calc the height of the current row
        h = t.row_height(row_idx)

        if y + h > absolute_bottom_margin
          start_new_page
          y = margin_top

          # draw the header cells
          draw_table_headers(t) if t.headers && (t.show_headers == :page)
          x, y = current_point
        end

        # loop over each column in the current row
        row.each_with_index do |cell, col_idx|

          # calc the options and widths for this particular cell
          opts = t.options_for(col_idx, row_idx)
          w = t.col_width(col_idx)

          # paint it
          self.cell(cell.data, x, y, w, h, opts)
          x += w
          move_to(x, y)
        end

        # move to the start of the next row
        y += h
        x = options[:left]
        move_to(x, y)
      end
    end
    
    def calc_table_dimensions(t)
      # TODO: when calculating the min cell width, we basically want the width of the widest character. At the
      #       moment I'm stripping all pango markup tags from the string, which means if any character is made
      #       intentioanlly large, we'll miss it and it might not fit into our table cell.
      # TODO: allow column widths to be set manually

      # calculate the min and max width of every cell in the table
      t.cells.each_with_index do |row, row_idx|
        row.each_with_index do |cell, col_idx|
          opts = t.options_for(col_idx, row_idx).only(default_text_options.keys)
          padding = opts[:padding] || 3
          cell.min_width  = text_width(cell.data.to_s.dup.gsub(/<.+?>/,"").gsub(/\b|\B/,"\n"), opts) + (padding * 4)
          cell.max_width  = text_width(cell.data, opts) + (padding * 4)
        end
      end

      # calculate the min and max width of every cell in the headers row
      if t.headers
        t.headers.each_with_index do |cell, col_idx|
          opts = t.options_for(col_idx, :headers).only(default_text_options.keys)
          padding = opts[:padding] || 3
          cell.min_width  = text_width(cell.data.to_s.dup.gsub(/<.+?>/,"").gsub(/\b|\B/,"\n"), opts) + (padding * 4)
          cell.max_width  = text_width(cell.data, opts) + (padding * 4)
        end
      end

      # let the table decide on the actual widths it will use for each col
      t.calc_col_widths!

      # now that we know how wide each column will be, we can calculate the 
      # height of every cell in the table
      t.cells.each_with_index do |row, row_idx|
        row.each_with_index do |cell, col_idx|
          opts = t.options_for(col_idx, row_idx).only(default_text_options.keys)
          padding = opts[:padding] || 3
          cell.height = text_height(cell.data, t.col_width(col_idx) - (padding * 2), opts) + (padding * 2)
        end
      end

      # let the table calculate how high each row is going to be
      t.calc_row_heights!

      # perform the same height calcs for the header row if necesary
      if t.headers
        t.headers.each_with_index do |cell, col_idx|
          opts = t.options_for(col_idx, :headers).only(default_text_options.keys)
          padding = opts[:padding] || 3
          cell.height = text_height(cell.data, t.col_width(col_idx) - (padding * 2), opts) + (padding * 2)
        end
        t.calc_headers_height!
      end
    end
    private :calc_table_dimensions

    def draw_table_headers(t)
      x, y = current_point
      origx = x
      h = t.headers_height
      t.headers.each_with_index do |cell, col_idx|
        # calc the options and widths for this particular header cell
        opts = t.options_for(col_idx, :headers)
        w = t.col_width(col_idx)

        # paint it
        self.cell(cell.data, x, y, w, h, opts)
        x += w
        move_to(x, y)
      end
      move_to(origx, y + h)
    end
    private :draw_table_headers

    # This class is used to hold all the data and options for a table that will
    # be added to a PDF::Wrapper document. Tables are a collection of cells, each
    # one rendered to the document using the Wrapper#cell function.
    #
    # To begin working with a table, pass in a 2d array of data to display, along
    # with optional headings, then pass the object to Wrapper#table
    #
    #    table = Table.new do |t|
    #      t.headers = ["Words", "Numbers"]
    #      t.data = [['one',  1],
    #                ['two',  2],
    #                ['three',3]]
    #    end
    #    pdf.table(table)
    #
    # For all but the most basic tables, you will probably want to tweak at least 
    # some of the options for some of the cells. The options available are the same
    # as those that are valid for the Wrapper#cell method, including things like font,
    # font size, color and alignment.
    #
    # Options can be specified at the table, column, row and cell level. When it comes time
    # to render each cell, the options are merged together so that cell options override row 
    # ones, row ones override column ones and column ones override table wide ones.
    #
    # By default, no options are defined at all, and the document defaults will be used.
    #
    # For example:
    #
    #    table = Table.new(:font_size => 10) do |t|
    #      t.headers = ["Words", "Numbers"]
    #      t.data = [['one',  1],
    #                ['two',  2],
    #                ['three',3]]
    #      t.row_options 0, :color => :green
    #      t.row_options 2, :color => :red
    #      t.col_options 0, :color => :blue
    #      t.cell_options 2, 2, :font_size => 18
    #      t.manual_column_width 2, 40
    #    end
    #    pdf.table(table)
    #
    # == Displaying Headings
    #
    # By default, the column headings will be displayed at the top of the table, and at
    # the start of each new page the table wraps on to. Use the show_headers= option
    # to change this behaviour. Valid values are nil for never, :once for just the at the
    # top of the table, and :page for the default.
    #
    class Table
      attr_reader :cells#, :headers
      attr_accessor :width, :show_headers

      #
      def initialize(opts = {})

        # default table options
        @table_options  = opts
        @col_options    = Hash.new({})
        @row_options    = Hash.new({})
        @manual_col_widths = {}
        @header_options = {}
        @show_headers  = :page

        yield self if block_given?
        self
      end

      # Specify the tables data.
      #
      # The single argument should be a 2d array like:
      #
      #   [[ "one", "two"],
      #    [ "one", "two"]]
      def data=(d)
        # TODO: raise an exception of the data rows aren't all the same size
        # TODO: ensure d is array-like
        @cells = d.collect do |row|
          row.collect do |str|
            Wrapper::Cell.new(str)
          end
        end
      end

      # Retrieve or set the table's optional column headers.
      #
      # With no arguments, the currents headers will be returned
      #
      #   t.headers
      #   => ["col one", "col two"]
      #
      # The first argument is an array of text to use as column headers
      #
      #   t.headers ["col one", "col two]
      #
      # The optional second argument sets the cell options for the header
      # cells. See PDF::Wrapper#cell for a list of possible options. 
      #
      #   t.headers ["col one", "col two], :color => :block, :fill_color => :black
      #
      # If the options hash is left unspecified, the default table options will 
      # be used.
      #
      def headers(h = nil, opts = {})
        # TODO: raise an exception of the size of the array does not match the size
        #       of the data row arrays
        # TODO: ensure h is array-like
        return @headers if h.nil?
        @headers = h.collect do |str|
          Wrapper::Cell.new(str)
        end
        @header_options = opts
      end

      def headers=(h)
        # TODO: remove this method at some point. Deprecation started on 10th August 2008.
        warn "WARNING: Table#headers=() is deprecated, headers should now be set along with header options using Table#headers()"
        headers h
      end

      # access a particular cell at location x, y
      def cell(col_idx, row_idx)
        @cells[row_idx, col_idx]
      end

      # Set or retrieve options that apply to every cell in the table.
      # For a list of valid options, see Wrapper#cell.
      #
      # WARNING. This method is deprecated. Table options should be passed to the
      #          PDF::Wrapper::Table constructor instead
      def table_options(opts = nil)
        # TODO: remove this method at some point. Deprecation started on 10th August 2008.
        warn "WARNING: Table#table_options() is deprecated, please see the documentation for PDF::Wrapper::Table"
        @table_options = @table_options.merge(opts) if opts
        @table_options
      end

      # set or retrieve options that apply to header cells
      # For a list of valid options, see Wrapper#cell.
      #
      # WARNING. This method is deprecated. Header options should be passed to the
      #          PDF::Wrapper::Table#headers method instead
      def header_options(opts = nil)
        # TODO: remove this method at some point. Deprecation started on 10th August 2008.
        warn "WARNING: Table#header_options() is deprecated, please see the documentation for PDF::Wrapper::Table"
        @header_options = @header_options.merge(opts) if opts
        @header_options
      end

      # set or retrieve options that apply to a single cell
      # For a list of valid options, see Wrapper#cell.
      def cell_options(col_idx, row_idx, opts = nil)
        raise ArgumentError, "#{col_idx},#{row_idx} is not a valid cell reference" unless @cells[row_idx] && @cells[row_idx][col_idx]
        @cells[row_idx][col_idx].options = @cells[row_idx][col_idx].options.merge(opts) if opts
        @cells[row_idx][col_idx].options
      end

      # set options that apply to 1 or more columns
      # For a list of valid options, see Wrapper#cell.
      # <tt>spec</tt>::     Which columns to add the options to. :odd, :even, a range, an Array of numbers or a number
      def col_options(spec, opts)
        each_column do |col_idx|
          if (spec == :even && (col_idx % 2) == 0) ||
             (spec == :odd  && (col_idx % 2) == 1) ||
             (spec.class == Range && spec.include?(col_idx)) ||
             (spec.class == Array && spec.include?(col_idx)) ||
             (spec.respond_to?(:to_i) && spec.to_i == col_idx)
            
            @col_options[col_idx] = @col_options[col_idx].merge(opts)
          end
        end
        self
      end

      # Manually set the width for 1 or more columns 
      #
      # <tt>spec</tt>::     Which columns to set the width for. :odd, :even, a range, an Array of numbers or a number
      #
      def manual_col_width(spec, width)
        width = width.to_f
        each_column do |col_idx|
          if (spec == :even && (col_idx % 2) == 0) ||
             (spec == :odd  && (col_idx % 2) == 1) ||
             (spec.class == Range && spec.include?(col_idx)) ||
             (spec.class == Array && spec.include?(col_idx)) ||
             (spec.respond_to?(:to_i) && spec.to_i == col_idx)
            
            @manual_col_widths[col_idx] = width
          end
        end
        self
      end

      # set options that apply to 1 or more rows
      # For a list of valid options, see Wrapper#cell.
      # <tt>spec</tt>::     Which columns to add the options to. :odd, :even, a range, an Array of numbers or a number
      def row_options(spec, opts)
        each_row do |row_idx|
          if (spec == :even && (row_idx % 2) == 0) ||
             (spec == :odd  && (row_idx % 2) == 1) ||
             (spec.class == Range && spec.include?(row_idx)) ||
             (spec.class == Array && spec.include?(row_idx)) ||
             (spec.respond_to?(:to_i) && spec.to_i == row_idx)
            
            @row_options[row_idx] = @col_options[row_idx].merge(opts)
          end
        end
        self
      end

      # calculate the combined options for a particular cell
      #
      # To get the options for a regular cell, use numbers to reference the exact cell:
      #
      #    options_for(3, 3)
      #
      # To get options for a header cell, use :headers for the row:
      #
      #    options_for(3, :headers)
      #
      def options_for(col_idx, row_idx = nil)
        opts = @table_options.dup
        opts.merge! @col_options[col_idx]
        if row_idx == :headers
          opts.merge! @header_options
        else
          opts.merge! @row_options[row_idx]
          opts.merge! @cells[row_idx][col_idx].options
        end
        opts
      end

      # Returns the required height for the headers row.
      # Essentially just the height of the tallest cell in the row.
      def headers_height
        raise "You must call calc_headers_height! before calling headers_height" if @headers_height.nil?
        @headers_height
      end

      # Returns the required height for a particular row.
      # Essentially just the height of the tallest cell in the row.
      def row_height(idx)
        raise "You must call calc_row_heights! before calling row_heights" if @row_heights.nil?
        @row_heights[idx]
      end

      # Returns the number of columns in the table
      def col_count
        @cells.first.size.to_f
      end

      # Returns the width of the specified column
      def col_width(idx)
        raise "You must call calc_col_widths! before calling col_width" if @col_widths.nil?
        @col_widths[idx]
      end

      # process the individual cell widths and decide on the resulting
      # width of each column in the table
      def calc_col_widths!
        @col_widths = calc_column_widths
      end

      # process the individual cell heights in the header and decide on the 
      # resulting height of each row in the table
      def calc_headers_height!
        @headers_height = @headers.collect { |cell| cell.height }.compact.max
      end

      # process the individual cell heights and decide on the resulting
      # height of each row in the table
      def calc_row_heights!
        @row_heights = @cells.collect do |row|
          row.collect { |cell| cell.height }.compact.max
        end
      end

      # forget row and column dimensions
      def reset!
        @col_widths = nil
        @row_heights = nil
      end

      private

      # the main smarts behind deciding on the width of each column. If possible,
      # each cell will get the maximum amount of space it wants. If not, some
      # negotiation happens to find the best possible set of widths.
      def calc_column_widths
        raise "Can't calculate column widths without knowing the overall table width" if self.width.nil?
        check_cell_widths

        max_col_widths = {}
        min_col_widths = {}
        each_column do |col|
          min_col_widths[col] = cells_in_col(col).collect { |c| c.min_width}.max.to_f
          max_col_widths[col] = cells_in_col(col).collect { |c| c.max_width}.max.to_f
        end
        # add header cells to the mix
        if @headers
          @headers.each_with_index do |cell, idx|
            min_col_widths[idx] = [cell.min_width.to_f, min_col_widths[idx]].max
            max_col_widths[idx] = [cell.max_width.to_f, max_col_widths[idx]].max
          end
        end

        # override the min and max col widths with manual ones where appropriate
        # freeze the values so that the algorithm that adjusts the widths
        # leaves them untouched
        @manual_col_widths.each { |key, val| val.freeze }
        max_col_widths.merge! @manual_col_widths
        min_col_widths.merge! @manual_col_widths

        if min_col_widths.values.sum > self.width
          raise RuntimeError, "table content cannot fit into a table width of #{self.width}"
        end
        
        if max_col_widths.values.sum == self.width
          # every col gets the space it wants
          col_widths = max_col_widths.dup
        elsif max_col_widths.values.sum < self.width
          # every col gets the space it wants, and there's
          # still more room left. Distribute the extra room evenly
          col_widths = grow_col_widths(max_col_widths.dup, max_col_widths, true)
        else
          # there's not enough room for every col to get as much space
          # as it wants, so work our way down until it fits
          col_widths = grow_col_widths(min_col_widths.dup, max_col_widths, false)
        end
        col_widths
      end

      # check to ensure every cell has a minimum and maximum cell width defined
      def check_cell_widths
        @cells.each do |row|
          row.each_with_index do |cell, col_idx|
            raise "Every cell must have a min_width defined before being rendered to a document" if cell.min_width.nil?
            raise "Every cell must have a max_width defined before being rendered to a document" if cell.max_width.nil?
            if @manual_col_widths[col_idx] && cell.min_width > @manual_col_widths[col_idx]
              raise "Manual width for col #{col_idx} is too low"
            end
          end
        end
        if @headers
          @headers.each_with_index do |cell, col_idx|
            raise "Every header cell must have a min_width defined before being rendered to a document" if cell.min_width.nil?
            raise "Every header cell must have a max_width defined before being rendered to a document" if cell.max_width.nil?
            if @manual_col_widths[col_idx] && cell.min_width > @manual_col_widths[col_idx]
              raise "Manual width for col #{col_idx} is too low"
            end
          end
        end
      end

      # iterate over each column in the table
      def each_column(&block)
        (0..(col_count-1)).each do |col|
          yield col
        end
      end

      # iterate over each row in the table
      def each_row(&block)
        (0..(@cells.size-1)).each do |row|
          yield row
        end
      end

      # an array of all the cells in the specified column
      def cells_in_col(idx)
        @cells.collect {|row| row[idx]}
      end

      # an array of all the cells in the specified row
      def cells_in_row(idx)
        @cells[idx]
      end

      # if the widths of every column are less than the total width
      # of the table, grow them to make use of it.
      #
      # col_widths - the current hash of widths for each column index
      # max_col_widths - the maximum width each column desires
      # past_max - can the width of a colum grow beyond its maximum desired
      def grow_col_widths(col_widths, max_col_widths, past_max = false)
        loop do
          each_column do |idx|
            col_widths[idx] += 0.3 unless col_widths[idx].frozen?
            col_widths[idx].freeze if col_widths[idx] >= max_col_widths[idx] && past_max == false
            break if col_widths.values.sum >= self.width
          end
          break if col_widths.values.sum >= self.width
        end
        col_widths
      end
    end

    # A basic container to hold the required information for each cell
    class Cell
      attr_accessor :data, :options, :height, :min_width, :max_width

      def initialize(str)
        @data = str
        @options = {}
      end
    end
  end
end
