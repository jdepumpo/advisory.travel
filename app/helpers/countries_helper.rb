module CountriesHelper
  def advisory_level(advisory)
    case advisory
    when 1
      return advise = { name: "Normal Precautions", color: "bg-green-400" }
    when 2
      return advise = { name: "Increased Caution", color: "bg-yellow-400" }
    when 3
      return advise = { name: "Reconsider Travel", color: "bg-orange-400" }
    when 4
      return advise = { name: "Do Not Travel", color: "bg-red-400" }
    else
      return advise = { name: "—", color: "bg-gray-200" }
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
