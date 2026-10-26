class ProcessStep < ApplicationRecord
  include BustsSiteCache
  include Auditable
  include FriendlySlug
  friendly_slug :title
  include SoftDeletable
  include Positionable
  include Publishable

  validates :title, presence: true

  def self.permission_resource = :content
end
