class ServiceOption < ApplicationRecord
  include Auditable
  include SoftDeletable
  include Positionable
  include Publishable

  KINDS = {
    "addon" => "Extra con precio fijo (casilla)",
    "quantity" => "Por cantidad (precio × unidades)",
    "choice" => "Opción de un grupo (elegir una)"
  }.freeze

  belongs_to :service, inverse_of: :options

  # Quitar una opción desde el formulario del servicio la envía a la papelera.
  # Se marca deleted_at en el momento para que el guardado anidado la incluya.
  attr_reader :remove

  def remove=(value)
    @remove = value
    return unless ActiveModel::Type::Boolean.new.cast(value)
    self.deleted_at ||= Time.current
    self.deleted_by_id = Current.user&.id
  end

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS.keys }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :group_name, presence: true, if: -> { kind == "choice" }
  validates :max_quantity, numericality: { greater_than_or_equal_to: :min_quantity }, if: -> { kind == "quantity" }

  def self.permission_resource = :content

  def display_name = "#{name} (#{service&.title})"

  def estimator_payload
    {
      id: id,
      name: name,
      description: description,
      kind: kind,
      group: group_name,
      price: price.to_f,
      unit: unit_label,
      min: min_quantity,
      max: max_quantity,
      default: default_selected
    }
  end
end
