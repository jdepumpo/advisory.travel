require 'sidekiq-scheduler'

class GetUsAdvisoriesJob < ApplicationJob
  queue_as :default
  include Sidekiq::Worker

  def perform(*args)
    state_to_iso_yml = YAML.load_file("#{Rails.root.to_s}/static_data/state_to_iso.yml")

    url = "https://travel.state.gov/_res/rss/TAsTWs.xml"

    URI.open(url) do |rss|
      feed = RSS::Parser.parse(rss, validate: false)
      feed.items.each do |item|
        pub_date = item.pubDate.to_date
        level_content = item.categories[0].content
        level_match = level_content.match(/\p{Digit}/)
        level_match ? level = level_match[0].to_i : next
        cc = item.categories[1].content
        state_code = state_to_iso_yml.find { |x| x["Tag"] == cc }
        next if state_code.nil?
        iso_code = state_code["ISO"]
        if Country.find_by(alpha2: iso_code)
          Advisory.create!(
            country: Country.find_by(alpha2: iso_code),
            level: level,
            issuer: Issuer.find_by(name: "US"),
            body: item.description,
            pub_date: pub_date
            )
          puts iso_code
        end
      end
    end
  end
end
