class Country < ApplicationRecord
  has_many :advisories

  def self.ransackable_attributes(_auth = nil) = %w[name region subregion]
  def self.ransackable_associations(_auth = nil) = %w[advisories]
end
