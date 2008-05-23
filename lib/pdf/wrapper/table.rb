module PDF
  class Wrapper
    class Table
      attr_reader :cells, :headers, :col_options, :row_options
      attr_accessor :options

      # data should be a 2d array
      #
      # [[ "one", "two"],
      #  [ "one", "two"]]
      def initialize(data, headers = nil)
        @cells = data.collect do |row|
          row.collect do |str|
            Wrapper::Cell.new(str)
          end
        end

        if headers
          @headers = headers.collect do |str|
            Wrapper::Cell.new(str)
          end
        end

        # default table options
        @options = {}

        # column options
        @col_options = Hash.new({})

        # row options
        @row_options = Hash.new({})
      end

      def options_for(col_idx, row_idx)
        opts = @options.dup
        opts.merge! @col_options[col_idx]
        opts.merge! @row_options[row_idx]
        opts.merge! @cells[row_idx][col_idx].options
        opts
      end

      def row_height(idx)
        @row_heights ||= @cells.collect do |row|
          row.collect { |cell| cell.height }.compact.max
        end
        @row_heights[idx]
      end

      def col_count
        @cells.first.size.to_f
      end

      def col_width(idx, table_width)
        @col_widths ||= calc_column_widths(table_width)
        @col_widths[idx]
      end

      def reset!
        @col_widths = nil
        @row_heights = nil
      end

      private

      def calc_column_widths(table_width)
        check_cell_widths

        max_col_widths = {}
        min_col_widths = {}
        each_column do |col|
          min_col_widths[col] = cells_in_col(col).collect { |c| c.min_width}.max.to_f
          max_col_widths[col] = cells_in_col(col).collect { |c| c.max_width}.max.to_f
        end

        if min_col_widths.values.sum > table_width
          raise RuntimeError, "table content cannot fit into a table width of #{table_width}"
        end
        
        if max_col_widths.values.sum == table_width
          # every col gets the space it wants
          col_widths = max_col_widths.dup
        elsif max_col_widths.values.sum < table_width
          # every col gets the space it wants, and there's
          # still more room left. Distribute the extra room evenly
          col_widths = max_col_widths.dup
          bonus = (table_width - @col_widths.values.sum).to_f
          per_col_bonus = bonus / col_count
          col_widths.each do |idx, w|
            col_widths[idx] = w + per_col_bonus
          end
        else
          # there's not enough room for every col to get as much space
          # as it wants, so work our way down until it fits
          col_widths = min_col_widths.dup
          loop do
            each_column do |idx|
              #col_widths[idx] = [w + 1, max_col_widths[idx]].min
              col_widths[idx] += 1 unless col_widths[idx].frozen?
              col_widths[idx].freeze if col_widths[idx] >= max_col_widths[idx]
              break if col_widths.values.sum >= table_width
            end
            break if col_widths.values.sum >= table_width
          end
        end
        col_widths
      end

      def check_cell_widths
        @cells.each do |row|
          row.each do |cell|
            raise "Every cell must have a min_width defined before being rendered to a document" if cell.min_width.nil?
            raise "Every cell must have a max_width defined before being rendered to a document" if cell.max_width.nil?
          end
        end
      end

      def each_column(&block)
        (0..(col_count-1)).each do |col|
          yield col
        end
      end

      def cells_in_col(idx)
        @cells.collect {|row| row[idx]}
      end

      def cells_in_row(idx)
        @cells[idx]
      end

    end

    class Cell
      attr_accessor :data, :options, :height, :min_width, :max_width

      def initialize(str)
        @data = str
        @options = {}
      end
    end
  end
end
