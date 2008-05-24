module PDF
  class Wrapper
    # load libpango if it isn't already loaded.
    # This will add some methods to the cairo Context class in addition to providing
    # its own classes and constants. A small amount of documentation is available at
    # http://ruby-gnome2.sourceforge.jp/fr/hiki.cgi?Cairo%3A%3AContext#Pango+related+APIs
    def load_libpango
      begin
        require 'pango' unless @context.respond_to? :create_pango_layout
      rescue LoadError
        raise LoadError, 'Ruby/Pango library not found. Visit http://ruby-gnome2.sourceforge.jp/'
      end
    end

    # load lib gdkpixbuf if it isn't already loaded.
    # This will add some methods to the cairo Context class in addition to providing
    # its own classes and constants.
    def load_libpixbuf
      begin
        require 'gdk_pixbuf2' unless @context.respond_to? :set_source_pixbuf
      rescue LoadError
        raise LoadError, 'Ruby/GdkPixbuf library not found. Visit http://ruby-gnome2.sourceforge.jp/'
      end
    end

    # load lib poppler if it isn't already loaded.
    # This will add some methods to the cairo Context class in addition to providing
    # its own classes and constants.
    def load_libpoppler
      begin
        require 'poppler' unless @context.respond_to? :render_poppler_page
      rescue LoadError
        raise LoadError, 'Ruby/Poppler library not found. Visit http://ruby-gnome2.sourceforge.jp/'
      end
    end

    # load librsvg if it isn't already loaded
    # This will add an additional method to the Cairo::Context class
    # that allows an existing SVG to be drawn directly onto it
    # There's a *little* bit of documentation at:
    # http://ruby-gnome2.sourceforge.jp/fr/hiki.cgi?Cairo%3A%3AContext#render_rsvg_handle
    def load_librsvg
      begin
        require 'rsvg2' unless @context.respond_to? :render_svg_handle
      rescue LoadError
        raise LoadError, 'Ruby/RSVG library not found. Visit http://ruby-gnome2.sourceforge.jp/'
      end
    end


  end
end
