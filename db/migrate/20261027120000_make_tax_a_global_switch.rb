# Un solo interruptor para el impuesto: si está apagado no aparece en el cotizador web,
# ni en las cotizaciones nuevas, ni en el PDF, ni en los correos. Antes solo existía
# «sumarlo en el cotizador web» y las cotizaciones lo cobraban igual.
class MakeTaxAGlobalSwitch < ActiveRecord::Migration[8.0]
  def change
    rename_column :site_settings, :estimator_shows_tax, :tax_enabled
    # Las solicitudes del cotizador guardan el impuesto que se le mostró a la persona
    add_column :quote_requests, :tax_amount, :decimal, precision: 12, scale: 2, null: false, default: 0
  end
end
