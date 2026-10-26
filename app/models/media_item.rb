class MediaItem < ApplicationRecord
  include BustsSiteCache
  include Auditable
  include FriendlySlug
  friendly_slug :title
  include SoftDeletable
  include Positionable
  include Publishable

  KINDS = { "photo" => "Foto", "video" => "Video" }.freeze

  mount_uploader :image, ImageUploader
  mount_uploader :video, VideoUploader

  belongs_to :category, optional: true
  # Una foto puede estar en varias galerías (álbumes y galerías generales de proyectos)
  has_many :placements, class_name: "MediaPlacement", dependent: :destroy, inverse_of: :media_item
  has_many :albums, through: :placements

  # Video subido directo a S3 desde el navegador (ver DirectUpload): llega la clave, no el archivo
  attr_accessor :video_direct_key

  validates :kind, inclusion: { in: KINDS.keys }
  validates :image, presence: { message: "es obligatoria (en videos es la portada)" }
  validates :video, presence: true, if: -> { kind == "video" && video_direct_key.blank? }
  validate :direct_video_uploaded, if: -> { video_direct_key.present? }
  after_save :attach_direct_video, if: -> { video_direct_key.present? }

  before_validation :default_title, prepend: true # antes del slug, que sale del título

  scope :in_gallery, -> { where(show_in_gallery: true) }
  scope :featured, -> { where(featured: true) }
  scope :photos, -> { where(kind: "photo") }
  scope :videos, -> { where(kind: "video") }
  scope :unplaced, -> { where.missing(:placements) }

  def self.permission_resource = :content

  # Busca una foto igual ya subida (misma huella) para no duplicarla.
  def self.find_duplicate(file)
    path = file.respond_to?(:path) ? file.path : file.to_s
    return unless path && File.exist?(path)
    kept.find_by(checksum: Digest::MD5.file(path).hexdigest)
  end

  def video? = kind == "video"
  def photo? = kind == "photo"

  def ratio
    width.to_i.positive? && height.to_i.positive? ? "#{width}/#{height}" : (video? ? "16/9" : "4/5")
  end

  def display_name = title.presence || "#{KINDS[kind]} ##{id}"

  # Galerías vivas donde aparece (álbumes y generales de proyecto)
  def galleries
    placements.includes(album: :project, project: []).filter_map do |p|
      gallery = p.album || p.project
      gallery if gallery&.kept?
    end
  end

  # Proyectos relacionados (directo o a través de un álbum)
  def projects
    galleries.filter_map { |g| g.is_a?(Album) ? g.project : g }.uniq
  end

  def in_gallery?(gallery) = MediaPlacement.for_gallery(gallery).exists?(media_item_id: id)

  def context_label
    names = galleries.map { |g| g.is_a?(Album) ? g.title : "#{g.title} · General" }
    case names.size
    when 0 then nil
    when 1 then names.first
    else "#{names.first} y #{names.size - 1} más"
    end
  end

  # Datos para el visor (lightbox).
  def lightbox_data(version: :large)
    {
      id: to_param, # va en el enlace directo: /galeria#foto-<slug>
      type: kind,
      src: video? ? video.url : image_url(version),
      thumb: image_url(:thumb),
      poster: video? ? image_url(:large) : nil,
      title: title,
      desc: description,
      ratio: ratio,
      duration: duration
    }.compact
  end

  private

  def direct_video_uploaded
    problem = DirectUpload.problem_with(video_direct_key, "video")
    errors.add(:video, problem) if problem
  end

  def attach_direct_video
    DirectUpload.attach!(self, :video, video_direct_key)
    self.video_direct_key = nil
  end

  def default_title
    return if title.present? || image.blank?
    base = image.file&.original_filename || image.file&.filename
    self.title = File.basename(base.to_s, ".*").tr("-_", "  ").squish.capitalize if base
  end

end
