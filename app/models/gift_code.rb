# == Schema Information
#
# Table name: gift_codes
#
#  id                  :bigint           not null, primary key
#  amount              :decimal(10, 2)   not null
#  claimed_at          :datetime
#  currency_code       :string(3)        not null
#  expires_at          :datetime         not null
#  status              :integer          default("created"), not null
#  unique_url          :string(32)       not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  administrator_id    :bigint
#  creation_request_id :string(40)       not null
#  gc_id               :string(255)      not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_gift_codes_on_administrator_id     (administrator_id)
#  index_gift_codes_on_creation_request_id  (creation_request_id) UNIQUE
#  index_gift_codes_on_unique_url           (unique_url) UNIQUE
#  index_gift_codes_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (administrator_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
class GiftCode < ApplicationRecord
  belongs_to :user
  belongs_to :administrator, optional: true

  enum status: { created: 0, sent: 1, claimed: 2 }

  validates :unique_url, presence: true, uniqueness: true, length: { is: 32 }
  validates :creation_request_id, presence: true, uniqueness: true, length: { is: 40 }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency_code, presence: true, length: { is: 3 }
  validates :gc_id, presence: true
  validates :expires_at, presence: true

  before_validation :generate_unique_url, on: :create
  before_validation :set_expiration, on: :create

  private

  def generate_unique_url
    self.unique_url = SecureRandom.hex(16)
  end

  def set_expiration
    self.expires_at = 30.days.from_now
  end
end
