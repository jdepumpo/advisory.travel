class Advisory < ApplicationRecord
  belongs_to :country
  belongs_to :issuer
end
