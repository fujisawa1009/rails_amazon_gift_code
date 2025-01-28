# == Schema Information
#
# Table name: administrators
#
#  id                     :bigint           not null, primary key
#  crypted_password       :string(255)
#  current_sign_in_at     :datetime
#  email                  :string(255)      not null
#  last_sign_in_at        :datetime
#  password_digest        :string(255)
#  reset_password_sent_at :datetime
#  reset_password_token   :string(255)
#  salt                   :string(255)
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_administrators_on_email                 (email) UNIQUE
#  index_administrators_on_reset_password_token  (reset_password_token) UNIQUE
#
class Administrator < ApplicationRecord
  authenticates_with_sorcery!
  has_many :admin_sessions, dependent: :destroy
  has_many :created_gift_codes, class_name: 'GiftCode', foreign_key: 'created_by'
  has_many :updated_gift_codes, class_name: 'GiftCode', foreign_key: 'updated_by'

  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }
  
  def admin?
    true
  end

end
