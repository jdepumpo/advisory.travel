namespace :advisories do
  desc "Refresh countries and travel advisories from external sources"
  task refresh: :environment do
    $stdout.sync = true
    AdvisoryImporter.run
  end
end
