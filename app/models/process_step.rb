class ProcessStep < ApplicationRecord
  include Auditable
  include SoftDeletable
  include Positionable
  include Publishable

  validates :title, presence: true

  def self.permission_resource = :content
end
