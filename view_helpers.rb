def result_color(pass_rate)
  if (pass_rate > 0.97)
    return "green"
  elsif (pass_rate <= 0.97) and (pass_rate > 0.6)
    return "yellow"
  else
    return "red"
  end
end

