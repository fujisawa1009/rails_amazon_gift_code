class GiftCode < ApplicationRecord
    belongs_to :user
    
    enum status: { created: 0, sent: 1, claimed: 2 }
    
    validates :unique_url, presence: true, uniqueness: true
    validates :amount, presence: true, numericality: { greater_than: 0 }
    validates :currency_code, presence: true
    validates :creation_request_id, presence: true, uniqueness: true
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
  