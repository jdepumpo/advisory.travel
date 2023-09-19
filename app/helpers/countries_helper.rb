module CountriesHelper
  def get_emoji_flag(alpha2)
    return ISO3166::Country[alpha2].emoji_flag
  end

  def advisory_level_color(advisory)
    if advisory && advisory.level == 1
      return "bg-green-400"
    elsif advisory && advisory.level == 2
      return "bg-yellow-400"
    elsif advisory && advisory.level == 3
      return "bg-orange-400"
    elsif advisory && advisory.level == 4
      return "bg-red-400"
    else
      return ""
    end
  end

  def advisory_level_name(advisory)
    if advisory && advisory.level == 1
      return "No Advisory"
    elsif advisory && advisory.level == 2
      return "Increased Caution"
    elsif advisory && advisory.level == 3
      return "Reconsider Travel"
    elsif advisory && advisory.level == 4
      return "Do Not Travel"
    else
      return ""
    end
  end

  def advisory_level_fraction(advisory)
    return "<sup>#{advisory.level}</sup>&#x2044;<sub>4</sub>"
  end
end
