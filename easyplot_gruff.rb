require 'rubygems'
require 'gruff'

module EasyPlot
  class EasyPlot
    @@default_opts = {
      :font => { "" => { :color => '#000000', :size => { :marker => 16, :legend => 20 } } },
      :width => 600,
      :background => 'transparent'
    }

    def EasyPlot.pie_chart data, options = {}
      opts = @@default_opts.merge(options)

      g = Gruff::Pie.new opts[:width]

      data.each do |k,v|
        g.data k, v[:value], v[:color]
      end


      g.theme = {
        #:colors => opts[:colors],
        :marker_color => 'blue',
        :background_colors => opts[:background]
      }

      font = opts[:font].keys.first
      g.font = font unless font == ''
      g.marker_font_size = opts[:font][font][:size][:marker]
      g.legend_font_size = opts[:font][font][:size][:legend]
      g.font_color = opts[:font][font][:color]

      g.to_blob
    end
  end
end
