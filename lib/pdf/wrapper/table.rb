module PDF
  class Wrapper
    
    # This class is used to hold all the data and options for a table that will
    # be added to a PDF::Wrapper document. Tables are a collection of cells, each
    # one rendered to the document using the Wrapper#cell function.
    #
    # To begin working with a table, pass in a 2d array of data to display, along
    # with optional headings, then pass the object to Wrapper#table
    #
    #    headings = ["Words", "Numbers"]
    #    data = [['one',  1],
    #            ['two',  2],
    #            ['three',3]]
    #    table = Table.new(data, headings)
    #    pdf.table(table)
    #
    # For all but the most basic tables, you will probably want to tweak at least 
    # some of the options for some of the cells. The options available are the same
    # as those that are valid for the Wrapper#cell method, including things like font,
    # font size, color and alignment.
    #
    # Options can be specified at the table, column, row and cell level. When it comes time
    # to render each cell, the options are merged together so that cell options over row 
    # ones, row ones of column ones and column ones over table wide ones.
    #
    # By default, no options are defined at all, and the document defaults will be used.
    #
    # For example:
    #
    #    headings = ["Words", "Numbers"]
    #    data = [['one',  1],
    #            ['two',  2],
    #            ['three',3]]
    #    table = Table.new(data, headings)
    #    table.options = {:font_size => 10}
    #    table.row_options[0] = {:color => :green}
    #    table.row_options[1] = {:color => :red}
    #    table.col_options[0] = {:color => :blue}
    #    table.cell(2,2) = {:font_size => 18}
    #    pdf.table(table)
    #
    # == Displaying Headings
    #
    # By default, the column headings will be displayed at the top of the table, and at
    # the start of each new page the table wraps on to. Use the show_headings= option
    # to change this behaviour. Valid values are nil for never, :once for just the at the
    # top of the table, and :page for the default.
    #
    class Table
      attr_reader :cells, :headers
      attr_accessor :width, :show_headings

      # Create a new table object.
      #
      # data should be a 2d array
      #
      #   [[ "one", "two"],
      #    [ "one", "two"]]
      #
      # headers should be a single array
      #  
      #   ["first", "second"]
      def initialize

        # default table options
        @table_options  = {}
        @col_options    = Hash.new({})
        @row_options    = Hash.new({})
        @header_options = {}
        @show_headings  = :page

        yield self if block_given?
        self
      end

      def data=(d)
        # TODO: ensure d is array-like
        @cells = d.collect do |row|
          row.collect do |str|
            Wrapper::Cell.new(str)
          end
        end
      end

      def headers=(h)
        # TODO: ensure h is array-like
        @headers = h.collect do |str|
          Wrapper::Cell.new(str)
        end
      end

      # access a particular cell
      def cell(col_idx, row_idx)
        @cells[row_idx, col_idx]
      end

      # Set or retrieve options that apply to every cell in the table.
      # For a list of valid options, see Wrapper#cell.
      def table_options(opts = nil)
        @table_options = @table_options.merge(opts) if opts
        @table_options
      end

      # set or retrieve options that apply to header cells
      # For a list of valid options, see Wrapper#cell.
      def header_options(opts = nil)
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

      # set or retrieve options that apply to 1 or more columns
      # For a list of valid options, see Wrapper#cell.
      def col_options(idx, opts = nil)
        # TODO: allow idx to be a range, :odd, :even, array of ints
        @col_options[idx] = @col_options[idx].merge(opts) if opts
        @col_options[idx]
      end

      # set or retrieve options that apply to 1 or more rows
      # For a list of valid options, see Wrapper#cell.
      def row_options(idx, opts = nil)
        # TODO: allow idx to be a range, :odd, :even, array of ints
        @row_options[idx] = @col_options[idx].merge(opts) if opts
        @row_options[idx]
      end

      # calculate the combined options for a particular cell
      #
      # To get the options for a regular cell, use numbers to refernce the exact cell:
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

      # ceck to ensure every cell has a minimum and maximum cell width defined
      def check_cell_widths
        @cells.each do |row|
          row.each do |cell|
            raise "Every cell must have a min_width defined before being rendered to a document" if cell.min_width.nil?
            raise "Every cell must have a max_width defined before being rendered to a document" if cell.max_width.nil?
          end
        end
        if @headers
          @headers.each do |cell|
            raise "Every header cell must have a min_width defined before being rendered to a document" if cell.min_width.nil?
            raise "Every header cell must have a max_width defined before being rendered to a document" if cell.max_width.nil?
          end
        end
      end

      # iterate over each column in the table
      def each_column(&block)
        (0..(col_count-1)).each do |col|
          yield col
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
      # col_widths - the cuurect hash of widths for each column index
      # max_col_widths - the maximum width each column desires
      # pas_max - can the width of a colum grow beyond its maximum desired
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
