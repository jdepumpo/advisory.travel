module ApplicationHelper
  include Pagy::Frontend
  include Heroicon::Engine.helpers

  def page_title
    "advisory.travel | #{controller_name.humanize} | Travel advisories for countries around the world"
  end

  def body_class
    "#{controller_name}-#{action_name}"
  end

  def nav_link_class(section, extra = nil)
    if section == controller_name
      "bg-amber-900 text-white px-3 py-2 rounded-md text-sm font-medium #{extra}"
    else
      "text-amber-300 hover:bg-amber-700 hover:text-white px-3 py-2 rounded-md text-sm font-medium #{extra}"
    end
  end

  def get_emoji_flag(alpha2)
    return ISO3166::Country[alpha2].emoji_flag
  end

  def time_ago(time_object)
    "#{time_ago_in_words(time_object)} ago"
  end

  def format_time(time_object)
    l(time_object, format: :long)
  end
end
