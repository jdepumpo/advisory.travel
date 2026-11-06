class Advisory < ApplicationRecord
  belongs_to :country
  belongs_to :issuer

  def self.ransackable_attributes(_auth = nil) = %w[level]
  def self.ransackable_associations(_auth = nil) = []

  ransacker :average_advisories do
    Arel.sql('average')
  end
end
