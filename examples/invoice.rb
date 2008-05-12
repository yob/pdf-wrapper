#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.font("Sans Serif")
pdf.line_width(0.1)
# naglowek
pdf.cell("Exorigo", pdf.absolute_left_margin, pdf.absolute_top_margin, pdf.body_width*0.2, 30, :alignment => :center)
pdf.cell("Zamówienie nr PO/0000/01/01/2008", pdf.absolute_left_margin+pdf.body_width*0.2, pdf.absolute_top_margin, pdf.body_width*0.8, 30, :fill_color => :gray, :alignment => :center)
pdf.cell("imię i naziwsko osoby zamawiającej. NALEŻY PODAĆ NA FAKTURZE", pdf.absolute_left_margin, pdf.absolute_top_margin+30, pdf.body_width*0.55, 14, :font_size => 6)
pdf.cell("data zamówienia", pdf.absolute_left_margin+pdf.body_width*0.55, pdf.absolute_top_margin+30, pdf.body_width*0.15, 14, :font_size => 6)
pdf.cell("POWYŻSZY NUMER ZAMÓWIENIA NALEŻY PODAĆ NA FAKTURZE", pdf.absolute_left_margin+pdf.body_width*0.7, pdf.absolute_top_margin+30, pdf.body_width*0.3, 30, :font_size => 6, :alignment => :center, :spacing => 4)
pdf.cell("Jan Kowalski", pdf.absolute_left_margin, pdf.absolute_top_margin+44, pdf.body_width*0.55, 16, :font => "Sans Serif bold", :font_size => 8)
pdf.cell("22.01.2008", pdf.absolute_left_margin+pdf.body_width*0.55, pdf.absolute_top_margin+44, pdf.body_width*0.15, 16, :font => "Sans Serif bold", :font_size => 8)
# dane dostawcy

# szczegoly zamowienia

# autoryzacja

# adres
pdf.render_to_file("dupa.pdf")
