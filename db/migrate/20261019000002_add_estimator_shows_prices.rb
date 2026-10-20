# Permite usar el cotizador sin mostrar montos: la persona arma su pedido y el equipo
# recibe el estimado calculado para mandar la propuesta.
class AddEstimatorShowsPrices < ActiveRecord::Migration[8.0]
  def change
    add_column :site_settings, :estimator_shows_prices, :boolean, null: false, default: true
  end
end
