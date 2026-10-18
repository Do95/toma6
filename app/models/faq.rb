class Faq < ApplicationRecord
  include Auditable
  include SoftDeletable
  include Positionable
  include Publishable

  validates :question, :answer, presence: true

  def self.permission_resource = :content
end
