module Admin
  # Ajustes del sistema: cotizaciones, PDF, impuestos y papelera. Solo administradores.
  class SettingsController < BaseController
    self.permission_resource = :settings

    FIELDS = %i[
      currency_symbol currency_code tax_name tax_rate estimator_shows_tax estimator_shows_prices bundle_discount_percent bundle_min_services
      estimator_disclaimer quote_prefix quote_number_year quote_number_digits quote_number_start request_prefix quote_validity_days quote_default_notes quote_default_terms quote_payment_info
      pdf_logo remove_pdf_logo notification_email trash_retention_days
    ].freeze

    def edit
      @setting = settings
    end

    def update
      @setting = settings
      if @setting.update(params.require(:site_setting).permit(*FIELDS))
        redirect_to edit_admin_settings_path, notice: "Ajustes guardados."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
