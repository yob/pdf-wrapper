#!/usr/bin/env ruby
# coding: utf-8

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.font("Sans Serif")
pdf.line_width(0.1)
# naglowek
pdf.translate(pdf.absolute_left_margin, pdf.absolute_top_margin) do
  pdf.scale(pdf.body_width, pdf.body_width) do
    pdf.cell("Exorigo", 0, 0, 0.2, 0.05, :alignment => :center, :font_size => 15)
    pdf.cell("Zamówienie nr PO/0000/01/01/2008", 0.2, 0, 0.8, 0.05, :fill_color => :gray, :alignment => :center)
    pdf.cell("imię i naziwsko osoby zamawiającej. NALEŻY PODAĆ NA FAKTURZE", 0, 0.05, 0.55, 0.025, :font_size => 6)
    pdf.cell("data zamówienia", 0.55, 0.05, 0.15, 0.025, :font_size => 6)
    pdf.cell("POWYŻSZY NUMER ZAMÓWIENIA NALEŻY PODAĆ NA FAKTURZE", 0.7, 0.05, 0.3, 0.05, :font_size => 6, :alignment => :center, :spacing => 4)
    pdf.cell("Jan Kowalski", 0, 0.075, 0.55, 0.025, :font => "Sans Serif bold", :font_size => 8)
    pdf.cell("22.01.2008", 0.55, 0.075, 0.15, 0.025, :font => "Sans Serif bold", :font_size => 8)
  end
end
# dane dostawcy

# szczegoly zamowienia

# autoryzacja

# adres
pdf.render_to_file("scaled-cells.pdf")
