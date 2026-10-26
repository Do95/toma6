# Ubicación de una foto o video en una galería (un álbum o la galería general
# de un proyecto). Cada galería tiene su propio orden.
class MediaPlacement < ApplicationRecord
  include BustsSiteCache
  include Auditable
  include RandomSlug

  belongs_to :media_item, inverse_of: :placements
  belongs_to :album, optional: true, inverse_of: :placements
  belongs_to :project, optional: true

  validate :exactly_one_gallery
  validates :media_item_id, uniqueness: { scope: :album_id }, if: :album_id
  validates :media_item_id, uniqueness: { scope: :project_id, conditions: -> { where(album_id: nil) } }, unless: :album_id

  scope :ordered, -> { order(:position, :id) }

  before_create :append_position
  after_destroy_commit :log_detach

  def self.permission_resource = :content

  # Agrega una foto a una galería sin duplicar. gallery: Album o Project.
  def self.attach!(media_item, gallery)
    attrs = gallery.is_a?(Album) ? { album: gallery } : { project: gallery, album_id: nil }
    find_or_create_by!(attrs.merge(media_item: media_item))
  end

  # "album-12" / "project-5" ↔ registro
  # "album-boda-sofia" / "project-boda-sofia": va en filtros y formularios, sin ids
  def self.gallery_key(gallery) = "#{gallery.is_a?(Album) ? 'album' : 'project'}-#{gallery.to_param}"

  def self.gallery_from_key(key)
    type, param = key.to_s.split("-", 2)
    model = { "album" => Album, "project" => Project }[type]
    model && param.present? ? model.kept.friendly.find(param) : nil
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Todas las galerías posibles, para selectores: [[etiqueta, clave], …]
  def self.gallery_options
    projects = Project.kept.ordered.includes(:albums).to_a
    loose_albums = Album.kept.where(project_id: nil).ordered.to_a
    options = projects.flat_map do |project|
      [["#{project.title} · General", gallery_key(project)]] +
        project.albums.map { |a| ["#{project.title} › #{a.title}", gallery_key(a)] }
    end
    options + loose_albums.map { |a| ["Álbum suelto › #{a.title}", gallery_key(a)] }
  end

  def self.for_gallery(gallery)
    gallery.is_a?(Album) ? where(album: gallery) : where(project: gallery, album_id: nil)
  end

  def gallery = album || project
  def display_name = "#{media_item&.display_name} en «#{gallery_label}»"
  def gallery_label = album ? album.display_name : "#{project&.title} · General"

  private

  def exactly_one_gallery
    errors.add(:base, "Elegí un álbum o un proyecto") if album_id.present? == project_id.present?
  end

  def append_position
    return if position.to_i.positive?
    scope = album_id ? self.class.where(album_id: album_id) : self.class.where(project_id: project_id, album_id: nil)
    self.position = (scope.maximum(:position) || 0) + 1
  end

  def log_detach
    ActivityLog.record!(media_item, "detach", { "galería" => [gallery_label, nil] }) if media_item
  end
end
