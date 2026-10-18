module Positionable
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order(:position, :id) }
    before_create :set_default_position
  end

  private

  def set_default_position
    return if position.to_i.positive?
    self.position = (self.class.unscoped.maximum(:position) || 0) + 1
  end
end
