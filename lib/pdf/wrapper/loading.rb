module PDF
  class Wrapper
    # load libpango if it isn't already loaded.
    # This will add some methods to the cairo Context class in addition to providing
    # its own classes and constants. A small amount of documentation is available at
    # http://ruby-gnome2.sourceforge.jp/fr/hiki.cgi?Cairo%3A%3AContext#Pango+related+APIs
    def load_libpango
      return if @context.respond_to? :create_pango_layout

      begin
        require 'pango'
      rescue LoadError
        raise LoadError, 'Ruby/Pango library not found. Visit http://ruby-gnome2.sourceforge.jp/'
      end
    end

    # load lib gdkpixbuf if it isn't already loaded.
    # This will add some methods to the cairo Context class in addition to providing
    # its own classes and constants.
    def load_libpixbuf
      return if @context.respond_to? :set_source_pixbuf

      begin
        require 'gdk_pixbuf2'
      rescue LoadError
        raise LoadError, 'Ruby/GdkPixbuf library not found. Visit http://ruby-gnome2.sourceforge.jp/'
      end
    end

    # load lib poppler if it isn't already loaded.
    # This will add some methods to the cairo Context class in addition to providing
    # its own classes and constants.
    def load_libpoppler
      return if @context.respond_to? :render_poppler_page

      begin
        require 'gtk2'
      rescue Gtk::InitError
        # ignore this error, it's thrown when gtk2 is loaded with no xsession available.
        # as advised at http://www.ruby-forum.com/topic/182949
      end
      begin
        require 'poppler'
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
      return if @context.respond_to? :render_svg_handle

      begin
        require 'rsvg2'
      rescue LoadError
        raise LoadError, 'Ruby/RSVG library not found. Visit http://ruby-gnome2.sourceforge.jp/'
      end
    end
  end
end
