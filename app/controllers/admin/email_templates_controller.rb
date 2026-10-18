module Admin
  # Textos de los correos automáticos.
  class EmailTemplatesController < BaseController
    self.permission_resource = :settings

    before_action :load_template, except: :index

    def index
      EmailTemplate.ensure_defaults!
      @templates = EmailTemplate.order(:id)
    end

    def edit; end

    def update
      if @template.update(params.require(:email_template).permit(:subject, :heading, :body, :button_label, :recipients, :enabled))
        redirect_to edit_admin_email_template_path(@template), notice: "Plantilla guardada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def restore
      @template.restore_defaults!
      redirect_to edit_admin_email_template_path(@template), notice: "Se restauró el texto original."
    end

    # Vista previa con datos de ejemplo
    def preview
      message = SampleMail.build(@template.key)
      html = message.html_part&.body&.decoded || message.body.decoded
      render html: html.to_s.html_safe, layout: false
    rescue StandardError => e
      render html: "<p style='font-family:sans-serif;padding:20px'>No se pudo generar la vista previa: #{ERB::Util.h(e.message)}</p>".html_safe, layout: false
    end

    # Manda una prueba a tu propio correo con datos de ejemplo
    def test
      log = SampleMail.deliver_test(@template.key, current_user.email)
      notice = log ? "Te enviamos una prueba a #{current_user.email}. El resultado aparece en el historial de correos." : "No se pudo preparar la prueba."
      redirect_to edit_admin_email_template_path(@template), notice: notice
    end

    private

    def load_template
      @template = EmailTemplate.find(params[:id])
    end

    def required_action = action_name.in?(%w[index edit preview]) ? :read : :write
  end
end
