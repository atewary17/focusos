class Device < ApplicationRecord
  KINDS = %w[android laptop].freeze
  # Writable by the app on sign-in.
  SIGN_IN_ATTRIBUTES = %i[kind name manufacturer model os_version app_version].freeze

  belongs_to :user
  has_many :api_tokens, dependent: :destroy

  validates :kind, inclusion: { in: KINDS }
  validates :installation_id, presence: true, uniqueness: { scope: :user_id }
  validates :name, presence: true, length: { maximum: 100 }
  validates :manufacturer, :model, :os_version, :app_version, length: { maximum: 100 }

  def signed_in?
    api_tokens.active.exists?
  end
end
