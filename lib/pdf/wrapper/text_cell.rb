# coding: utf-8

module PDF
  class Wrapper
    class TextCell

      attr_reader :data, :min_width, :natural_width, :max_width, :wrapper
      attr_accessor :width, :height
      attr_writer :options

      def initialize(str)
        @data = str.to_s
        @options = {}
      end

      def draw(wrapper, x, y)
        @wrapper = wrapper

        wrapper.cell(self.data, x, y, self.width, self.height, self.options)
      end

      def calculate_width_range(wrapper)
        @wrapper = wrapper

        padding = options[:padding] || 3
        if options[:markup] == :pango
          str = self.data.dup.gsub(/<.+?>/,"").gsub("&amp;","&").gsub("&lt;","<").gsub("&gt;",">")
          options.delete(:markup)
        else
          str = self.data.dup
        end
        @min_width  = wrapper.text_width(str.gsub(/\b|\B/,"\n"), text_options) + (padding * 4)
        @natural_width = wrapper.text_width(str, text_options) + (padding * 4)
      end

      def calculate_height(wrapper)
        raise "Cannot calculate height until cell width is set" if self.width.nil?

        @wrapper = wrapper

        padding = options[:padding] || 3
        @height = wrapper.text_height(self.data, self.width - (padding * 2), text_options) + (padding * 2)
      end

      def options
        @options ||= {}
      end

      def text_options
        self.options.only(wrapper.default_text_options.keys)
      end
    end
  end
end
