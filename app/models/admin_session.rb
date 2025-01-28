# == Schema Information
#
# Table name: admin_sessions
#
#  id               :bigint           not null, primary key
#  expires_at       :datetime         not null
#  session_token    :string(255)      not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  administrator_id :bigint           not null
#
# Indexes
#
#  index_admin_sessions_on_administrator_id  (administrator_id)
#  index_admin_sessions_on_session_token     (session_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (administrator_id => administrators.id)
#
class AdminSession < ApplicationRecord
  belongs_to :administrator

  validates :session_token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :set_session_token, on: :create
  before_validation :set_expiration, on: :create

  private

  def set_session_token
    self.session_token = SecureRandom.hex(32)
  end

  def set_expiration
    self.expires_at = 24.hours.from_now
  end
end