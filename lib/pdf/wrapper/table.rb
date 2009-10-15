module PDF
  class Wrapper

    # Draws a basic table of text on the page. See the documentation for PDF::Wrapper::Table to get
    # a detailed description of how to control the table and its appearance. If data is an array,
    # it can contain Cell-like objects (see PDF::Wrapper::TextCell and PDF::Wrapper::TextImageCell)
    # or any objects that respond to to_s().
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
      t.draw(self, options[:left], options[:top])
    end

    # This class is used to hold all the data and options for a table that will
    # be added to a PDF::Wrapper document. Tables are a collection of cells, each
    # one individually rendered to the document in a location that makes it appear
    # to be a table.
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
    # == Complex Cells
    #
    # By default, any cell content described in the data array is converted to a string and
    # wrapped in a TextCell object. If you need to, it is possible to define your cells
    # as cell-like objects manually to get more control.
    #
    # The following two calls are equivilant:
    #
    #   data = [[1,2]]
    #   pdf.table(data)
    #
    #   data = [[PDF::Wrapper::TextCell.new(2),PDF::Wrapper::TextCell.new(2)]]
    #   pdf.table(data)
    #
    # An alternative to a text-only cell is a cell with text and an image. These
    # cells must be initialised with a filename and cell dimensions (width and height)
    # as calculating automatic dimensions is difficult.
    #
    #   data = [
    #     ["James", PDF::Wrapper::TextImageCell.new("Healy","photo-jim.jpg",100,100)],
    #     ["Jess", PDF::Wrapper::TextImageCell.new("Healy","photo-jess.jpg",100,100)],
    #   ]
    #   pdf.table(data)
    #
    # If TextImageCell doesn't meet your needs, you are free to define your own
    # cell-like object and use that.
    #
    class Table
      attr_reader :cells, :wrapper
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

      # Set the table data.
      #
      # The single argument should be a 2d array like:
      #
      #   [[ "one", "two"],
      #    [ "one", "two"]]
      #
      # The cells in the array can be any object with to_s() defined, or a Cell-like
      # object (such as a TextCell or TextImageCell).
      #
      def data=(d)
        row_sizes = d.map { |row| row.size }.compact.uniq
        raise ArgumentError, "" if row_sizes.size > 1

        @cells = d.collect do |row|
          row.collect do |data|
            if data.kind_of?(Wrapper::TextCell) || data.kind_of?(Wrapper::TextImageCell)
              data
            else
              Wrapper::TextCell.new(data.to_s)
            end
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
        return @headers if h.nil?

        if @cells && @cells.first.size != h.size
          raise ArgumentError, "header column count does not match data column count"
        end

        @headers = h.collect do |data|
          if data.kind_of?(Wrapper::TextCell) || data.kind_of?(Wrapper::TextImageCell)
            data
          else
            Wrapper::TextCell.new(data.to_s)
          end
        end
        @header_options = opts
      end

      def draw(wrapper, tablex, tabley)
        @wrapper = wrapper

        calculate_dimensions

        # move to the start of our table (the top left)
        wrapper.move_to(tablex, tabley)

        # draw the header cells
        draw_table_headers if self.headers && (self.show_headers == :page || self.show_headers == :once)

        x, y = wrapper.current_point

        # loop over each row in the table
        self.cells.each_with_index do |row, row_idx|

          # calc the height of the current row
          h = row.first.height

          if y + h > wrapper.absolute_bottom_margin
            wrapper.start_new_page
            y = wrapper.margin_top

            # draw the header cells
            draw_table_headers if self.headers && (self.show_headers == :page)
            x, y = wrapper.current_point
          end

          # loop over each column in the current row and paint it
          row.each_with_index do |cell, col_idx|
            cell.draw(wrapper, x, y)
            x += cell.width
            wrapper.move_to(x, y)
          end

          # move to the start of the next row
          y += h
          x = tablex
          wrapper.move_to(x, y)
        end
      end

      # access a particular cell at location x, y
      def cell(col_idx, row_idx)
        @cells[row_idx][col_idx]
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

      # Returns the number of columns in the table
      def col_count
        @cells.first.size.to_f
      end

      # iterate over each cell in the table. Yields a cell object.
      #
      def each_cell(&block)
        each_row do |row_idx|
          cells_in_row(row_idx).each do |cell|
            yield cell
          end
        end
      end

      private

      def draw_table_headers
        x, y = wrapper.current_point
        origx = x
        h = self.headers.first.height
        self.headers.each_with_index do |cell, col_idx|
          cell.draw(wrapper, x, y)
          x += cell.width
          wrapper.move_to(x, y)
        end
        wrapper.move_to(origx, y + h)
      end

      # calculate the dimensions of each row and column in the table. The order
      # here is crucial. First we ask each cell to caclulate the range of
      # widths they can render with, then we make a decision on the actual column
      # width and pass that on to every cell.
      #
      # Once each cell knows how wide it will be it can calculate how high it
      # will be. With that done the table cen determine the tallest cell in
      # each row and pass that onto each cell so every cell in a row renders
      # with the same height.
      #
      def calculate_dimensions
        calculate_cell_width_range
        calculate_column_widths
        calculate_cell_heights
        calculate_row_heights
      end


      def calculate_cell_width_range
        # TODO: when calculating the min cell width, we basically want the width of the widest character. At the
        #       moment I'm stripping all pango markup tags from the string, which means if any character is made
        #       intentioanlly large, we'll miss it and it might not fit into our table cell.

        # calculate the min and max width of every cell in the table
        cells.each_with_index do |row, row_idx|
          row.each_with_index do |cell, col_idx|
            cell.options = self.options_for(col_idx, row_idx)
            cell.calculate_width_range(wrapper)
          end
        end

        # calculate the min and max width of every cell in the headers row
        if self.headers
          self.headers.each_with_index do |cell, col_idx|
            cell.options = self.options_for(col_idx, :headers)
            cell.calculate_width_range(wrapper)
          end
        end
      end

      def calculate_cell_heights
        cells.each_with_index do |row, row_idx|
          row.each_with_index do |cell, col_idx|
            cell.calculate_height(wrapper)
          end
        end

        # perform the same height calcs for the header row if necesary
        if self.headers
          self.headers.each_with_index do |cell, col_idx|
            cell.calculate_height(wrapper)
          end
        end
      end

      # process the individual cell heights and decide on the resulting
      # height of each row in the table
      def calculate_row_heights
        @cells.each do |row|
          row_height = row.collect { |cell| cell.height }.compact.max
          row.each { |cell| cell.height = row_height }
        end
      end

      # the main smarts behind deciding on the width of each column. If possible,
      # each cell will get the maximum amount of space it wants. If not, some
      # negotiation happens to find the best possible set of widths.
      #
      def calculate_column_widths
        raise "Can't calculate column widths without knowing the overall table width" if self.width.nil?

        min_col_widths = {}
        natural_col_widths = {}
        max_col_widths = {}
        each_column do |col|
          min_col_widths[col] = cells_in_col(col).collect { |c| c.min_width}.max
          natural_col_widths[col] = cells_in_col(col).collect { |c| c.natural_width}.max
          max_col_widths[col] = cells_in_col(col).collect { |c| c.max_width}.compact.max
        end

        # override the min and max col widths with manual ones where appropriate
        max_col_widths.merge! @manual_col_widths
        natural_col_widths.merge! @manual_col_widths
        min_col_widths.merge! @manual_col_widths

        if min_col_widths.values.sum > self.width
          raise RuntimeError, "table content cannot fit into a table width of #{self.width}"
        else
          # there's not enough room for every col to get as much space
          # as it wants, so work our way down until it fits
          col_widths = grow_col_widths(min_col_widths.dup, natural_col_widths, max_col_widths)
          col_widths.each do |col_index, width|
            cells_in_col(col_index).each do |cell|
              cell.width = width
            end
          end
        end
      end

      # iterate over each column in the table. Yields a column index, not
      # actual columns or cells.
      #
      def each_column(&block)
        (0..(col_count-1)).each do |col|
          yield col
        end
      end

      # iterate over each row in the table. Yields an row index, not actual rows
      # or cells.
      #
      def each_row(&block)
        (0..(@cells.size-1)).each do |row|
          yield row
        end
      end

      # an array of all the cells in the specified column, including headers
      #
      def cells_in_col(idx)
        ret = []
        ret << @headers[idx] if @headers
        ret += @cells.collect {|row| row[idx]}
        ret
      end

      # an array of all the cells in the specified row
      def cells_in_row(idx)
        @cells[idx]
      end

      # starting with very low widths for each col, bump each column width up
      # until we reach the width of the entire table.
      #
      # columns that are less than their "natural width" are given preference.
      # If every column has reached its natural width then each column is
      # increased in an equal manor.
      #
      # starting col_widths 
      #     the hash of column widths to start from. Should generally match the
      #     absolute smallest width each column can render in
      # natural_col_widths
      #     the hqash of column widths where each column will be able to render
      #     itself fully without wrapping
      # max_col_widths 
      #     the hash of absolute maximum column widths, no column width can go
      #     past this. Can be nil, which indicates there's no maximum
      #
      def grow_col_widths(starting_col_widths, natural_col_widths, max_col_widths)
        col_widths = starting_col_widths.dup
        loop do
          each_column do |idx|
            if col_widths.values.sum >= natural_col_widths.values.sum ||
                 col_widths[idx] < natural_col_widths[idx]
              if max_col_widths[idx].nil? || col_widths[idx] < max_col_widths[idx]
                col_widths[idx] += 0.3
              else
                col_widths[idx] = max_col_widths[idx]
              end
            end
            break if col_widths.values.sum >= self.width
          end
          break if col_widths.values.sum >= self.width
        end
        col_widths
      end
    end
  end
end
