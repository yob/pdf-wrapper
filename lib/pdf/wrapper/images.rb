module PDF
  class Wrapper
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
    # <tt>:center</tt>::    If the image is scaled, it will be centered horizontally and vertically
    # <tt>:rotate</tt>::    The desired rotation. One of :counterclockwise, :upsidedown, :clockwise.
    #                       Doesn't work with PNG, PDF or SVG files.
    #
    # left and top default to the current cursor location
    # width and height default to the size of the imported image
    # padding defaults to 0
    def image(filename, opts = {})
      # TODO: add some options for justification and padding
      raise ArgumentError, "file #{filename} not found" unless File.file?(filename)
      opts.assert_valid_keys(default_positioning_options.keys + [:padding, :proportional, :center, :rotate])

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
        draw_pixbuf filename, opts
      end
    end

    private

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

    # if need be, translate the x,y co-ords for an image to something different
    #
    # arguments:
    # <tt>x</tt>::    The current x co-ord of the image
    # <tt>y</tt>::    The current x co-ord of the image
    # <tt>desired_w</tt>::    The image width requested by the user
    # <tt>desired_h</tt>::    The image height requested by the user
    # <tt>actual_w</tt>::    The width of the image we're going to draw
    # <tt>actual_h</tt>::    The height of the image we're going to draw
    # <tt>centre</tt>::    True if the image should be shifted to the center of it's box
    def calc_image_coords(x, y, desired_w, desired_h, actual_w, actual_h, centre = false)

      # if the width of the image is less than the requested box, calculate
      # the white space buffer
      if actual_w < desired_w && centre
        white_space = desired_w - actual_w
        x = x + (white_space / 2)
      end

      # if the height of the image is less than the requested box, calculate
      # the white space buffer
      if actual_h < desired_h && centre
        white_space = desired_h - actual_h
        y = y + (white_space / 2)
      end

      return x, y
    end

    # given a list of desired and actual image dimensions, calculate the
    # size the image should actually be rendered at
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
      x, y = calc_image_coords(opts[:left] || x, opts[:top] || y, opts[:width] || w, opts[:height] || h, width, height,  opts[:center])
      @context.save do
        @context.translate(x, y)
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
      if opts[:rotate]
        pixbuf = pixbuf.rotate( rotation_constant( opts[:rotate] ) )
      end
      width, height = calc_image_dimensions(opts[:width], opts[:height], pixbuf.width, pixbuf.height, opts[:proportional])
      x, y = calc_image_coords(opts[:left] || x, opts[:top] || y, opts[:width] || pixbuf.width, opts[:height] || pixbuf.height, width, height,  opts[:center])
      @context.save do
        @context.translate(x, y)
        @context.scale(width / pixbuf.width, height / pixbuf.height)
        @context.set_source_pixbuf(pixbuf, 0, 0)
        @context.paint
      end
      move_to(opts[:left] || x, (opts[:top] || y) + height)
    rescue Gdk::PixbufError
      raise ArgumentError, "Unrecognised image format (#{filename})"
    end

    def rotation_constant( rotation )
      Gdk::Pixbuf.const_get "ROTATE_#{rotation.to_s.upcase}"
    end

    def draw_png(filename, opts = {})
      # based on a similar function in rabbit. Thanks Kou.
      x, y = current_point
      img_surface = Cairo::ImageSurface.from_png(filename)
      width, height = calc_image_dimensions(opts[:width], opts[:height], img_surface.width, img_surface.height, opts[:proportional])
      x, y = calc_image_coords(opts[:left] || x, opts[:top] || y, opts[:width] || img_surface.width, opts[:height] || img_surface.height, width, height,  opts[:center])
      @context.save do
        @context.translate(x, y)
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
      x, y = calc_image_coords(opts[:left] || x, opts[:top] || y, opts[:width] || handle.width, opts[:height] || handle.height, width, height,  opts[:center])
      @context.save do
        @context.translate(x, y)
        @context.scale(width / handle.width, height / handle.height)
        @context.render_rsvg_handle(handle)
        #@context.paint
      end
      move_to(opts[:left] || x, (opts[:top] || y) + height)
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

  end
end
