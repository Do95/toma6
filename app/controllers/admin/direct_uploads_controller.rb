module Admin
  # Firma la subida directa a S3 (ver DirectUpload). Valida tipo y tamaño antes de que
  # el navegador empiece a subir.
  class DirectUploadsController < BaseController
    self.permission_resource = :content

    def create
      upload = DirectUpload.presign(filename: params[:filename], content_type: params[:content_type],
                                    size: params[:size], kind: params[:kind])
      render json: upload
    rescue DirectUpload::Invalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error("[DirectUpload] #{e.class}: #{e.message}")
      render json: { error: "No se pudo preparar la subida. Probá de nuevo en un momento." }, status: :service_unavailable
    end

    private

    def required_action = :write
  end
end
