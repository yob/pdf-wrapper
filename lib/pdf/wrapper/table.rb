module PDF
  class Wrapper
    class Table
      attr_reader :cells, :headers
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

        @options = {}
      end

      def options_for(col_idx, row_idx)
        {}
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
        if @col_widths.nil?
          @col_widths ||= {}
          (0..(col_count-1)).each do |col|
            @col_widths[col] = 0
            @cells.each do |row|
              cell = row[col]
              @col_widths[col] = cell.width if cell.width > @col_widths[col]
            end
          end
          
          # reduce the width of columns that need less than their
          # fair share of space
          @col_widths.each do |col_idx, width|
            if width < table_width / col_count
              @col_widths[col_idx] = width
            end
          end

          loop do
            (0..(col_count-1)).each do |col|
              if @col_widths[col] > table_width / col_count
                @col_widths[col] -= 1
              end
              break if @col_widths.values.sum <= table_width
            end
            break if @col_widths.values.sum <= table_width
          end
        end
        @col_widths[idx]
      end

      def reset!
        @col_widths = nil
        @row_heights = nil
      end

    end

    class Cell
      attr_accessor :data, :options, :height, :width

      def initialize(str)
        @data = str
        @options = {}
      end
    end
  end
end
