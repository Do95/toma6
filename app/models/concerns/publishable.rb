module Publishable
  extend ActiveSupport::Concern

  included do
    scope :published, -> { where(published: true) }
    scope :visible, -> { kept.published }
  end

  def visible? = published? && (!respond_to?(:kept?) || kept?)
end
