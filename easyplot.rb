require 'rubygems'
require 'rchart'
require 'color'

module EasyPlot
  class EasyPlot
    @@default_opts = {
      :font => { "tahoma.ttf" => 6 },
      :width => 600,
      :height => 600,
      :radius => 0,
      :explosion => 0,
      :format => "png",
      :center => nil
    }

    def EasyPlot.pie_chart data, options = {}
      points = []
      labels = []
      colors = []

      opts = @@default_opts.merge(options)

      data.each do |k,v|
        labels << k
        points << v[:value]
        m = Color::RGB.from_html(v[:color])
        colors << [m.red, m.green, m.blue]
      end

      p = Rdata.new
      p.add_point(points, "s1");
      p.add_point(labels, "s2");
      p.add_all_series
      p.set_abscise_label_serie("s2");

      ch = Rchart.new(opts[:width], opts[:height])
      min_dim = [opts[:width], opts[:height]].min
      unless opts[:radius] > 1
        radius = min_dim/2 - 65
      else
        radius = opts[:radius]
      end

      ch.load_color_palette(colors)
      font = opts[:font].keys.first
      ch.set_font_properties(font, opts[:font][font])

      center_x = opts[:width]/2
      center_y = opts[:height]/2
      if opts[:center].is_a? Hash
        center_x = opts[:center][:x]
        center_y = opts[:center][:y]
      end
      ch.draw_flat_pie_graph(p.get_data, p.get_data_description, center_x, center_y, radius, Rchart::PIE_PERCENTAGE_LABEL, opts[:explosion])

      case opts[:format]
      when "jpg"
        ch.render_jepeg_str
      when "gif"
        ch.render_gif_str
      else
        return ch.render_png_str
      end
    end
  end
end
