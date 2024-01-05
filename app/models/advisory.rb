class Advisory < ApplicationRecord
  belongs_to :country
  belongs_to :issuer
  ransacker :average_advisories do
    Arel.sql('average')
  end
end
