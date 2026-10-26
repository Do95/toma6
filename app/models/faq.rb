class Faq < ApplicationRecord
  include Auditable
  include FriendlySlug
  friendly_slug :question
  include SoftDeletable
  include Positionable
  include Publishable

  validates :question, :answer, presence: true

  def self.permission_resource = :content
end
