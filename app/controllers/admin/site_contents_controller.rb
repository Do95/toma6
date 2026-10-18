module Admin
  # Textos, imágenes y datos de contacto que aparecen en el sitio público.
  class SiteContentsController < BaseController
    self.permission_resource = :content

    FIELDS = %i[
      site_name legal_name logo remove_logo wordmark remove_wordmark og_image remove_og_image
      hero_claim hero_subtitle hero_primary_cta hero_secondary_cta ticker_primary ticker_secondary manifesto
      about_title about_lead about_body about_closing
      services_title services_intro work_title work_intro gallery_title gallery_intro
      process_title process_intro faq_title faq_intro quote_title quote_intro contact_title contact_intro
      contact_email whatsapp_number phone address city country instagram_url facebook_url tiktok_url youtube_url
      site_url seo_title seo_description google_analytics_id footer_text
    ].freeze

    def edit
      @setting = settings
      @tab = params[:tab].presence || "general"
    end

    def update
      @setting = settings
      if @setting.update(params.require(:site_setting).permit(*FIELDS))
        redirect_to edit_admin_site_content_path(tab: params[:tab]), notice: "Contenido del sitio actualizado."
      else
        @tab = params[:tab].presence || "general"
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
