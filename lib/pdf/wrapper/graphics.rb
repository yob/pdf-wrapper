module PDF
  class Wrapper

    # draw a circle with radius r and a centre point at (x,y).
    # Parameters:
    # <tt>:x</tt>::   The x co-ordinate of the circle centre.
    # <tt>:y</tt>::   The y co-ordinate of the circle centre.
    # <tt>:r</tt>::   The radius of the circle
    #
    # Options:
    # <tt>:color</tt>::   The colour of the circle outline
    # <tt>:line_width</tt>::   The width of outline. Defaults to 0.5
    # <tt>:fill_color</tt>::   The colour to fill the circle with. Defaults to nil (no fill)
    def circle(x, y, r, options = {})
      options.assert_valid_keys(:color, :line_width, :fill_color)

      save_coords_and_state do
        move_to(x + r, y)

        # if the circle should be filled in
        if options[:fill_color]
          @context.save do
            color(options[:fill_color])
            @context.circle(x, y, r).fill
          end
        end

        color(options[:color])           if options[:color]
        line_width(options[:line_width]) if options[:line_width]
        @context.circle(x, y, r).stroke
      end
    end

    # draw a line from x1,y1 to x2,y2
    #
    # Options:
    # <tt>:color</tt>::   The colour of the line
    # <tt>:line_width</tt>::   The width of line. Defaults its 0.5
    def line(x0, y0, x1, y1, options = {})
      options.assert_valid_keys(:color, :line_width)

      save_coords_and_state do
        color(options[:color])           if options[:color]
        line_width(options[:line_width]) if options[:line_width]
        move_to(x0,y0)
        @context.line_to(x1,y1).stroke
      end
    end

    # change the default line width used to draw stroke on the canvas
    #
    # Parameters:
    # <tt>f</tt>:: float value of stroke width from 0.01 to 255
    def line_width(f)
      @line_width = f
      @context.set_line_width @context.device_to_user_distance(f,f).max
    end
    alias line_width= line_width

    # Adds a cubic Bezier spline to the path from the  (x0, y0) to position (x3, y3)
    # in user-space coordinates, using (x1, y1) and (x2, y2) as the control points.
    # Options:
    # <tt>:color</tt>::   The colour of the line
    # <tt>:line_width</tt>::   The width of line. Defaults to 0.5
    def curve(x0, y0, x1, y1, x2, y2, x3, y3, options = {})
      options.assert_valid_keys(:color, :line_width)

      save_coords_and_state do
        color(options[:color])           if options[:color]
        line_width(options[:line_width]) if options[:line_width]
        move_to(x0,y0)
        @context.curve_to(x1, y1, x2, y2, x3, y3).stroke
      end
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
    # <tt>:line_width</tt>::   The width of outline. Defaults to 0.5
    # <tt>:fill_color</tt>::   The colour to fill the rectangle with. Defaults to nil (no fill)
    # <tt>:radius</tt>::   If specified, the rectangle will have rounded corners with the specified radius
    def rectangle(x, y, w, h, options = {})
      options.assert_valid_keys(:color, :line_width, :fill_color, :radius)

      save_coords_and_state do
        # if the rectangle should be filled in
        if options[:fill_color]
          @context.save do
            color(options[:fill_color])
            if options[:radius]
              @context.rounded_rectangle(x, y, w, h, options[:radius]).fill
            else
              @context.rectangle(x, y, w, h).fill
            end
          end
        end

        color(options[:color])           if options[:color]
        line_width(options[:line_width]) if options[:line_width]

        if options[:radius]
          @context.rounded_rectangle(x, y, w, h, options[:radius]).stroke
        else
          @context.rectangle(x, y, w, h).stroke
        end
      end
    end

  end
end
