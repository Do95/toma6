class SiteSetting < ApplicationRecord
  include BustsSiteCache
  mount_uploader :logo, LogoUploader
  mount_uploader :wordmark, LogoUploader
  mount_uploader :pdf_logo, LogoUploader
  mount_uploader :og_image, ImageUploader

  belongs_to :updater, class_name: "User", foreign_key: :updated_by_id, optional: true

  validates :site_name, presence: true
  validates :tax_rate, :bundle_discount_percent, numericality: { greater_than_or_equal_to: 0, less_than: 100 }
  validates :trash_retention_days, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 365 }
  validates :quote_validity_days, numericality: { only_integer: true, greater_than: 0 }
  validates :quote_prefix, :request_prefix, format: { with: /\A[A-Za-z0-9]{1,8}\z/, message: "solo letras y números (hasta 8)" }
  validates :quote_number_digits, numericality: { only_integer: true, in: 3..8 }
  validates :quote_number_start, numericality: { only_integer: true, greater_than: 0 }
  validates :contact_email, :notification_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  before_save { self.updated_by_id = Current.user.id if Current.user && changed? }
  after_update_commit :log_update

  def self.current
    Current.site_setting ||= first || create!(site_name: "toma6")
  end

  def display_name = "Contenido y ajustes del sitio"

  def ticker_primary_words = split_words(ticker_primary)
  def ticker_secondary_words = split_words(ticker_secondary)

  def whatsapp_url
    digits = whatsapp_number.to_s.gsub(/\D/, "")
    digits.present? ? "https://wa.me/#{digits}" : nil
  end

  def public_base_url
    site_url.presence&.chomp("/") || begin
      opts = Rails.application.config.action_mailer.default_url_options || {}
      port = opts[:port] ? ":#{opts[:port]}" : ""
      "#{opts[:protocol] || 'http'}://#{opts[:host] || 'localhost'}#{port}"
    end
  end

  def bundle_discount? = bundle_discount_percent.to_d.positive?

  private

  def split_words(value) = value.to_s.split(",").map(&:strip).reject(&:blank?)

  def log_update
    changes = saved_changes.except("updated_at", "updated_by_id")
    return if changes.empty?
    ActivityLog.record!(self, "update", changes.transform_values { |(a, b)| [a.to_s.truncate(200), b.to_s.truncate(200)] })
  end
end
