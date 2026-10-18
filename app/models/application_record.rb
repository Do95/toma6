class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Nombre legible para listados, papelera y bitácora.
  def display_name
    %i[title name question number email].each do |attr|
      value = try(attr)
      return value.to_s if value.present?
    end
    "#{self.class.model_name.human} ##{id}"
  end
end
