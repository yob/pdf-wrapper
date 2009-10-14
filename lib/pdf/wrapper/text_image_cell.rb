# coding: utf-8

module PDF
  class Wrapper
    class TextImageCell

      attr_reader :text, :min_width, :natural_width, :max_width, :wrapper
      attr_accessor :width, :height
      attr_writer :options

      def initialize(str, filename, width, height)
        @text = str.to_s
        @filename = filename
        @min_width = width
        @natural_width = width
        @max_width = width
        @height = height
        @options = {}
      end

      def draw(wrapper, x, y)
        @wrapper = wrapper

        wrapper.cell(self.text, x, y, self.width, self.height, self.options)
        wrapper.image(@filename, image_options(x,y))
      end

      def calculate_width_range(wrapper)
        # nothing required, width range set in constructor
      end

      def calculate_height(wrapper)
        # nothing required, height set in constructor
      end

      def options
        @options ||= {}
      end

      private

      def image_offset
        @image_offset ||= text_height + 4
      end

      def image_options(x, y)
        {
          :left => x,
          :top  => y + image_offset,
          :width => self.width,
          :height => self.height - image_offset,
          :proportional => true,
          :center => true
        }
      end

      def text_height
        padding = options[:padding] || 3
        wrapper.text_height(self.text, self.width - (padding * 2), text_options) + (padding * 2)
      end

      def text_options
        self.options.only(wrapper.default_text_options.keys)
      end

    end
  end
end
