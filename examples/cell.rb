#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__) + "/../lib")

require 'pdf/wrapper'

pdf = PDF::Wrapper.new(:paper => :A4)
pdf.cell("Given an index within a layout, determines the positions that of the strong and weak cursors if the insertion point is at that index. The position of each cursor is stored as a zero-width rectangle. The strong cursor location is the location where characters of the directionality equal to the base direction of the layout are inserted. The weak cursor location is the location where characters of the directionality opposite to the base direction of the layout are inserted.", 100, 100, 100, 200, {:border => "", :color => :white, :bgcolor => :black})
pdf.render_to_file("wrapper-cell.pdf")
