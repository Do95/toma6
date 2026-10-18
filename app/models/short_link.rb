# Enlace corto propio (toma6.com/l/codigo) con su QR. El destino se puede
# cambiar cuando quieras sin reimprimir el QR.
class ShortLink < ApplicationRecord
  include Auditable
  include SoftDeletable

  STYLES = {
    "brand" => "Marca toma6 (esquinas suaves, ojos rojos)",
    "classic" => "Clásico (negro sobre blanco)",
    "inverse" => "Tarjeta oscura (marco carbón)"
  }.freeze
  # Sin letras que se confunden al dictar o leer impreso (0/O, 1/l/I)
  ALPHABET = "abcdefghijkmnpqrstuvwxyz23456789".chars.freeze
  RESERVED = %w[admin api assets uploads l c qr new edit nuevo].freeze

  has_many :clicks, class_name: "ShortLinkClick", dependent: :delete_all

  validates :title, presence: true, length: { maximum: 120 }
  validates :destination_url, presence: true
  validates :code, presence: true, uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9][a-z0-9-]{1,40}\z/, message: "solo minúsculas, números y guiones (2 a 40)" },
                   exclusion: { in: RESERVED, message: "está reservado" }
  validates :qr_style, inclusion: { in: STYLES.keys }
  validates :qr_label, length: { maximum: 32 }
  validate :destination_is_web_address

  before_validation :normalize_code
  before_validation :assign_code, on: :create

  scope :recent, -> { order(created_at: :desc) }

  def self.permission_resource = :content

  def self.generate_code(length = 6)
    loop do
      code = Array.new(length) { ALPHABET.sample }.join
      break code unless unscoped.exists?(code: code) || RESERVED.include?(code)
    end
  end

  def display_name = title

  def expired? = expires_at.present? && expires_at < Time.current
  def live? = kept? && active? && !expired?

  def status_label
    return "En la papelera" if trashed?
    return "Vencido" if expired?
    active? ? "Activo" : "Pausado"
  end

  # Dirección corta pública (la que se comparte)
  def short_url(base = SiteSetting.current.public_base_url) = "#{base}/l/#{code}"
  # La que va dentro del QR: marca la visita como escaneo
  def qr_url(base = SiteSetting.current.public_base_url) = "#{short_url(base)}?s=qr"

  # Destino final con los parámetros UTM (si los hay)
  def final_url(base = SiteSetting.current.public_base_url)
    url = destination_url.to_s.strip
    url = "#{base}#{url}" if url.start_with?("/")
    utm = { utm_source: utm_source, utm_medium: utm_medium, utm_campaign: utm_campaign }.compact_blank
    return url if utm.empty?
    uri = URI.parse(url)
    query = URI.decode_www_form(uri.query.to_s).reject { |k, _| utm.key?(k.to_sym) } + utm.map { |k, v| [k.to_s, v] }
    uri.query = URI.encode_www_form(query)
    uri.to_s
  rescue URI::InvalidURIError
    url
  end

  def link_clicks_count = clicks_count - qr_clicks_count

  private

  def normalize_code
    self.code = code.to_s.strip.downcase.parameterize if code.present?
  end

  def assign_code
    self.code = self.class.generate_code if code.blank?
  end

  def destination_is_web_address
    url = destination_url.to_s.strip
    return if url.start_with?("/") && !url.start_with?("//")
    uri = URI.parse(url)
    errors.add(:destination_url, "tiene que empezar con https:// o / (una página del sitio)") unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:destination_url, "no es una dirección válida")
  end
end
