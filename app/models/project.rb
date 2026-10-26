class Project < ApplicationRecord
  include BustsSiteCache
  include Auditable
  include SoftDeletable
  include Positionable
  include Publishable
  include FriendlySlug
  include VideoEmbeddable
  friendly_slug :title

  mount_uploader :cover, ImageUploader
  mount_uploader :video, VideoUploader

  has_many :albums, -> { kept.ordered }, inverse_of: :project
  has_many :all_albums, class_name: "Album", dependent: :destroy
  # Galería general del proyecto (fotos que no están en un álbum en particular)
  has_many :general_placements, -> { where(album_id: nil).ordered }, class_name: "MediaPlacement", dependent: :destroy
  has_and_belongs_to_many :services
  has_many :sections, -> { kept.ordered }, inverse_of: :project
  has_many :all_sections, class_name: "Section", dependent: :destroy

  soft_delete_cascade :all_albums, :all_sections

  after_create :create_default_sections

  validates :title, presence: true
  validates :video_link, format: { with: %r{\Ahttps?://}i }, allow_blank: true

  scope :featured, -> { where(featured: true) }

  def self.permission_resource = :content

  # Galería general del proyecto
  def general_media = general_placements.filter_map { |p| p.media_item if p.media_item&.kept? }
  def loose_media = general_media.select(&:published?)

  # Todo lo del proyecto: galería general + álbumes publicados, sin repetir
  def visible_media
    (loose_media + albums.select(&:published?).flat_map(&:visible_media)).uniq
  end

  def hero_image_url(version = :large)
    return cover.url(version) if cover.present?
    visible_media.first&.image_url(version)
  end

  def has_video? = video.present? || video_link.present?

  def page_sections
    Section.ensure_project_defaults!(self)
    sections
  end

  def neighbors
    list = Project.visible.ordered.pluck(:slug)
    idx = list.index(slug) || 0
    prev_slug = list[idx - 1] if idx.positive?
    next_slug = list[idx + 1]
    [prev_slug && Project.find_by(slug: prev_slug), next_slug && Project.find_by(slug: next_slug)]
  end

  private

  def create_default_sections = Section.ensure_project_defaults!(self)
end
