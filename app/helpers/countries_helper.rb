module CountriesHelper
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
      return "bg-gray-200"
    end
  end

  def advisory_level_name(advisory)
    if advisory.present?
      case advisory.level
      when 1
        return "No Advisory"
      when 2
        return "Increased Caution"
      when 3
        return "Reconsider Travel"
      when 4
        return "Do Not Travel"
      else
        return "—"
      end
    else
      return "—"
    end
  end

  def advisory_level_fraction(advisory)
    return "<sup>#{advisory.level}</sup>&#x2044;<sub>4</sub>"
  end
end

def issuer_info(alpha2)
  case alpha2
  when "CA"
    issue_info = { gov: "Government of Canada", flag: "🇨🇦" }
  when "US"
    issue_info = { gov: "United States Department of State", flag: "🇺🇸" }
  else
    "—"
  end
end
