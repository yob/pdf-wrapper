**WARNING**

As of October 2011 this gem still works reasonably well but it is relatively
unmaintained.

The gnome2 bindings produce high quality PDFs, but are very memory hungry. I've
switched to prawn for my PDF generation needs to keep things pure ruby and
garbage collector friendly.

# Overview

PDF::Wrapper is a PDF generation library that uses the cairo and pango
native libraries to do the heavy lifting. It essentially just wraps these
general purpose graphics libraries with some sugar that makes them a little
easier to use for making PDFs. The idea is to lever the low level tools in
those libraries (drawing shapes, laying out text, importing raster images, etc)
to build some higher level tools - tables, text boxes, borders, lists,
repeating elements (headers/footers), etc.

The API started off *roughly* following that of PDF::Writer, but it has since
diverged significantly. I've spent some time contributing to a pure Ruby PDF
generation library (Prawn[http://github.com/sandal/prawn/tree]) and its elegant
and simple API is having a strong effect on the direction I've been taking
PDF::Wrapper.

A key motivation for writing this library is cairo's support for Unicode in PDFs.
All text functions in this library require UTF-8 input, although as a native
English speaker I've only tested non ASCII text a little, so any feedback is
welcome.

There also seems to be a lack of English documentation available for the ruby
bindings to cairo/pango, so I'm aiming to document the code as much as possible
to provide worked examples for others. I'm learning as I go though, so if regular
users of either library spot techniques that fail best practice, please let me know.

It's early days, so the API is far from stable and I'm hesitant to write extensive
documentation just yet. It's the price you pay for being an early adopter. The
examples/ dir should have a range of sample code, and I'll try to keep it up to
date.

I welcome all feedback, feature requests, patches and suggestions. In
particular, what high level widgets would you like to see? What do you use when
building reports and documents in GUI programs?

# Installation

The recommended installation method is via Rubygems.

  gem install pdf-wrapper

# Author

James Healy <jimmy@deefa.com>

# License

* GPL version 2 or the Ruby License
* Ruby: http://www.ruby-lang.org/en/LICENSE.txt

# Dependencies

As of September 2010 all these dependencies are satisfied by gems. All of them are bindings
to C libraries, so you will need the libraries and headers installed on your system
before installing them.

* ruby/cairo[http://cairographics.org/rcairo/]
* ruby/pango[http://ruby-gnome2.sourceforge.jp/]
* ruby/rsvg2[http://ruby-gnome2.sourceforge.jp/]
* ruby/gdkpixbuf[http://ruby-gnome2.sourceforge.jp/]
* ruby/poppler[http://ruby-gnome2.sourceforge.jp/]

# Compatibility

JRuby users, you're currently out of luck. In theory it should be possible to use the Java bindings
to the native libraries we need, but as I'm not a JRuby user, it's not an itch
I've been motivated to scratch.

Rubinius users, I have no idea.

Ruby1.9 users, the current release of ruby/cairo (1.5.1) added support for 1.9. PDF::Wrapper
itself is 1.9 compatible.
