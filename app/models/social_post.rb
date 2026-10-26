class SocialPost < ApplicationRecord
  include Auditable
  include RandomSlug
  include SoftDeletable

  STATUSES = {
    "draft" => "Borrador",
    "scheduled" => "Programada",
    "publishing" => "Publicando",
    "published" => "Publicada",
    "partial" => "Publicada con errores",
    "failed" => "Falló"
  }.freeze

  INSTAGRAM_CAPTION_LIMIT = 2200

  mount_uploader :image, ImageUploader
  belongs_to :media_item, optional: true

  validates :body, presence: true
  validates :body, length: { maximum: INSTAGRAM_CAPTION_LIMIT }, if: :to_instagram?
  validates :link, format: { with: %r{\Ahttps?://}i }, allow_blank: true
  validates :scheduled_at, presence: { message: "indicá fecha y hora" }, if: -> { status == "scheduled" }
  validate :scheduled_in_future, if: -> { status == "scheduled" && scheduled_at.present? && will_save_change_to_scheduled_at? }
  validate :at_least_one_network
  validate :instagram_needs_image
  validate :networks_available

  scope :recent, -> { order(Arel.sql("COALESCE(published_at, scheduled_at, created_at) DESC")) }
  scope :due, -> { kept.where(status: "scheduled").where("scheduled_at <= ?", Time.current) }

  def self.permission_resource = :social

  def status_label = STATUSES.fetch(status, status)
  def display_name = body.to_s.truncate(60)

  def image_source_url(version = :social)
    if image.present?
      image.url(version)
    elsif media_item&.image.present?
      media_item.image.url(version)
    end
  end

  def public_image_url
    url = image_source_url
    return if url.blank?
    url.start_with?("http") ? url : "#{SiteSetting.current.public_base_url}#{url}"
  end

  def networks
    [("Facebook" if to_facebook?), ("Instagram" if to_instagram?)].compact
  end

  def editable? = %w[draft scheduled failed].include?(status)

  private

  def scheduled_in_future
    errors.add(:scheduled_at, "tiene que ser en el futuro") if scheduled_at < 1.minute.ago
  end

  def at_least_one_network
    errors.add(:base, "Elegí al menos una red para publicar.") unless to_facebook? || to_instagram?
  end

  def instagram_needs_image
    return unless to_instagram?
    errors.add(:base, "Instagram necesita una imagen.") if image.blank? && media_item&.image.blank?
  end

  def networks_available
    meta = Integration.meta
    errors.add(:to_facebook, "no está conectado") if to_facebook? && !meta&.facebook_ready?
    errors.add(:to_instagram, "no está conectado") if to_instagram? && !meta&.instagram_ready?
  end
end
