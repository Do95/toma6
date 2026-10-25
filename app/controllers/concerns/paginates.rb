# Paginación de las listas del panel con Pagy.
module Paginates
  extend ActiveSupport::Concern

  included do
    include Pagy::Method
    helper_method :pagination
    before_action { Pagy::I18n.locale = I18n.locale } # textos del paginador en español
  end

  private

  # Devuelve los registros de la página pedida (?page=N) y deja el paginador en @pagy.
  # page_key: para varias listas paginadas en la misma pantalla (ej. la papelera).
  def paginate(scope, per: 30, page_key: nil)
    options = { limit: per }
    options[:page_key] = page_key if page_key
    pagy, records = pagy(:offset, scope, **options)
    @pagy = pagy
    records
  end

  def pagination = @pagy
end
