class Category < ApplicationRecord
  include BustsSiteCache
  include Auditable
  include SoftDeletable
  include Positionable
  include FriendlySlug
  friendly_slug :name

  has_many :media_items, dependent: :nullify

  validates :name, presence: true

  def self.permission_resource = :content
end
