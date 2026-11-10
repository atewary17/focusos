class User < ApplicationRecord
  DEFAULT_TIME_ZONE = "Asia/Kolkata".freeze

  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :subjects, dependent: :destroy
  has_many :topics, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :recurring_tasks, dependent: :destroy

  # Collected data first, so its rows are gone before the devices they reference.
  # delete_all: these tables can hold many rows and have no callbacks.
  has_many :app_usage_days, dependent: :delete_all
  has_many :app_sessions, dependent: :delete_all
  has_many :screen_events, dependent: :delete_all
  has_many :health_samples, dependent: :delete_all
  has_many :sleep_sessions, dependent: :delete_all
  has_many :check_ins, dependent: :delete_all
  has_many :api_tokens, dependent: :destroy
  has_many :devices, dependent: :destroy

  # Virtual checkbox on the sign-up form; the timestamp is what we store.
  attribute :terms_accepted, :boolean

  normalizes :email_address, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 60 }
  validates :email_address, presence: true, uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true
  validates :time_zone, inclusion: { in: ->(_user) { User.time_zone_ids }, message: "is not a valid time zone" }
  validates :terms_accepted, acceptance: { accept: true, message: "must be accepted to create an account" }, on: :create

  before_create { self.consented_at = Time.current }

  # IANA identifiers (e.g. "Asia/Kolkata"), which the Android app will also use.
  def self.time_zone_ids
    @time_zone_ids ||= ActiveSupport::TimeZone.all.map { |zone| zone.tzinfo.name }.uniq.freeze
  end

  # [label, IANA id] pairs for a <select>, one entry per IANA zone.
  def self.time_zone_options
    ActiveSupport::TimeZone.all.uniq { |zone| zone.tzinfo.name }.map { |zone| [ zone.to_s, zone.tzinfo.name ] }
  end

  def first_name
    name.split.first
  end
end
