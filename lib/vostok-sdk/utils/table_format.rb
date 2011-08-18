# Copyright 2010 Red Hat, Inc.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'rubygems'
require 'highline/import'
require 'vostok-sdk/config'
require 'vostok-sdk/model/cartridge'

module Vostok
  module SDK
    module Utils
      class TableFormat
        Object::HighLine.track_eof=false
        Object::HighLine.color_scheme = HighLine::ColorScheme.new do |cs|
            cs[:emphasis]       = [ :blue, :bold ]
            cs[:error]          = [ :red ]
            cs[:warn]           = [ :red ]
            cs[:debug]          = [ :red, :on_white, :bold ]
            cs[:conf]           = [ :green ]
            cs[:question]       = [ :magenta, :bold ]
            cs[:table]          = [ :blue ]
            cs[:table_header]   = [ :bold ]
            cs[:message]        = [ :bold ]
        end
        
        @@h = Object::HighLine.new
        def self.csay(str,*options)
            lastChar = str[-1..-1]
            h = @@h
            if lastChar == ' ' or lastChar == '\t'
                str=h.color(str[0..-2],*options)+lastChar
            else
                str=h.color(str,*options)
            end
            h.say(str)
        end
        
        def self.table( col_names, col_keys, col_sizes, rows, indent=0)
          self.print_row_delim(col_sizes,indent)
          print (" " * 4 * indent)
          csay("| ",:table)
          (0...col_names.size).each{ |i|
            csay(sprintf("%#{col_sizes[i]}s ",col_names[i]),:table_header)
            csay("| ",:table)
          }
          print "\n"
          self.print_row_delim(col_sizes,indent)
          rows.each{ |r|
            print(" " * 4 * indent)
            csay("| ",:table)
            (0...col_names.size).each{ |i|
              if not r[col_keys[i]].nil?
                printf "%#{col_sizes[i]}s ", r[col_keys[i]]
              else
                printf "%#{col_sizes[i]}s ", "   "
              end
              csay("| ", :table)
            }
            print "\n"
          }
          self.print_row_delim(col_sizes,indent)
        end

        def self.print_row_delim(col_sizes,indent)
          print(" " * 4 * indent)
          str = "+"
          col_sizes.each{ |s|
            str += "-"*(s+2)
            str += "+"
          }
          csay(str,:table)
        end
      end
    end
  end
end

