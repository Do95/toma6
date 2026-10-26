# Plan con precio cerrado del cotizador ("Boda completa", "Pack redes").
# Los servicios que cubre no suman su precio base; sus extras sí.
class Plan < ApplicationRecord
  include BustsSiteCache
  include Auditable
  include FriendlySlug
  friendly_slug :title
  include SoftDeletable
  include Positionable
  include Publishable

  has_and_belongs_to_many :services

  validates :title, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  def self.permission_resource = :content

  def display_name = title

  def feature_list = features.to_s.lines.map(&:strip).reject(&:blank?)

  def estimator_payload
    { id: id, title: title, price: price.to_f, included: services.select(&:visible?).map(&:id) }
  end
end
