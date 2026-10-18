class QuoteItem < ApplicationRecord
  belongs_to :quote, inverse_of: :items
  belongs_to :service, optional: true

  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  def compute_total
    self.total = (quantity.to_d * unit_price.to_d).round(2)
  end

  def summary
    "#{description} (#{quantity.to_d.to_s('F').sub(/\.0\z/, '')} × #{unit_price.to_d.to_s('F')})"
  end
end
