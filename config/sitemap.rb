# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://advisory.travel"

SitemapGenerator::Sitemap.create do
  add '/countries'
  add '/map'
  Country.find_each do |country|
    add country_path(country), :lastmod => country.updated_at
  end
end
