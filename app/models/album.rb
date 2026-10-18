class Album < ApplicationRecord
  include Auditable
  include SoftDeletable
  include Positionable
  include Publishable
  include FriendlySlug
  friendly_slug :title

  mount_uploader :cover, ImageUploader

  belongs_to :project, optional: true, inverse_of: :albums
  belongs_to :cover_media_item, class_name: "MediaItem", optional: true
  # Las fotos viven en la biblioteca: el álbum solo las ubica (no las borra).
  has_many :placements, -> { ordered }, class_name: "MediaPlacement", dependent: :destroy, inverse_of: :album

  validates :title, presence: true

  scope :in_gallery, -> { where(show_in_gallery: true) }

  def self.permission_resource = :content

  # Fotos del álbum en su orden (sin las que están en la papelera)
  def media_items = placements.filter_map { |p| p.media_item if p.media_item&.kept? }
  def visible_media = media_items.select(&:published?)

  def cover_url(version = :medium)
    return cover.url(version) if cover.present?
    return cover_media_item.image_url(version) if cover_media_item&.kept? && cover_media_item.image.present?
    visible_media.first&.image_url(version)
  end

  # Tres fotos para la tarjeta "abanico" del álbum (la portada primero).
  def preview_urls(limit = 3)
    list = visible_media
    list = [cover_media_item, *(list - [cover_media_item])] if cover_media_item && list.include?(cover_media_item)
    list.first(limit).map { |m| m.image_url(:thumb) }.compact
  end

  def display_name = project ? "#{title} · #{project.title}" : title

end
