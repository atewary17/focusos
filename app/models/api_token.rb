# Bearer tokens for the Android app and scripts. Only a SHA-256 digest is stored;
# the plain token is returned once, by `issue!`.
class ApiToken < ApplicationRecord
  PREFIX = "fo_".freeze

  belongs_to :user
  belongs_to :device, optional: true

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  # Returns [api_token, plain_token].
  def self.issue!(**attributes)
    plain = PREFIX + SecureRandom.base58(32)
    [ create!(**attributes, token_digest: digest(plain)), plain ]
  end

  def self.authenticate(plain)
    active.includes(:user, :device).find_by(token_digest: digest(plain)) if plain.present?
  end

  def self.digest(plain)
    OpenSSL::Digest::SHA256.hexdigest(plain)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  # Avoids a database write on every request.
  def touch_last_used!
    update_column(:last_used_at, Time.current) if last_used_at.nil? || last_used_at < 1.minute.ago
  end
end
