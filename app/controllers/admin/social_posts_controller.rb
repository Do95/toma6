module Admin
  # Publicaciones para Facebook e Instagram. Se desbloquea al conectar una página en Integraciones.
  class SocialPostsController < ResourceController
    self.resource_class = SocialPost
    self.permission_resource = :social

    before_action :require_unlocked, except: :index

    def index
      @integration = Integration.meta
      return render(:locked) unless social_unlocked?
      scope = SocialPost.kept.recent.includes(:media_item, :creator)
      scope = scope.where(status: params[:status]) if SocialPost::STATUSES.key?(params[:status])
      @records = paginate(scope, per: 20)
    end

    def new
      @integration = Integration.meta
      @record = SocialPost.new(to_facebook: @integration.facebook_ready?, to_instagram: @integration.instagram_ready?)
      prefill_from_context
      load_media_library
    end

    def create
      @record = SocialPost.new(record_params)
      apply_intent
      if @record.save
        enqueue_if_needed
        redirect_to admin_social_posts_path, notice: intent_notice
      else
        @integration = Integration.meta
        load_media_library
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      return redirect_to(admin_social_posts_path, alert: "Las publicaciones ya enviadas no se pueden editar.") unless @record.editable?
      @integration = Integration.meta
      load_media_library
    end

    def update
      return redirect_to(admin_social_posts_path, alert: "Las publicaciones ya enviadas no se pueden editar.") unless @record.editable?
      @record.assign_attributes(record_params)
      apply_intent
      if @record.save
        enqueue_if_needed
        redirect_to admin_social_posts_path, notice: intent_notice
      else
        @integration = Integration.meta
        load_media_library
        render :edit, status: :unprocessable_entity
      end
    end

    def publish_now
      authorize!(:social, :write)
      @record.update_columns(status: "publishing", scheduled_at: nil)
      PublishSocialPostJob.perform_later(@record.id, current_user.id)
      redirect_to admin_social_posts_path, notice: "Publicando… actualizá en unos segundos para ver el resultado."
    end

    private

    def require_unlocked
      redirect_to admin_social_posts_path unless social_unlocked?
    end

    def intent = params[:intent].presence_in(%w[publish schedule draft]) || "draft"

    def apply_intent
      case intent
      when "publish" then @record.status = "publishing"; @record.scheduled_at = nil
      when "schedule" then @record.status = "scheduled"
      else @record.status = "draft"
      end
    end

    def enqueue_if_needed
      PublishSocialPostJob.perform_later(@record.id, current_user.id) if intent == "publish"
    end

    def intent_notice
      case intent
      when "publish" then "Publicando en #{@record.networks.to_sentence}… el estado se actualiza en unos segundos."
      when "schedule" then "Programada para el #{I18n.l(@record.scheduled_at, format: :long)}."
      else "Borrador guardado."
      end
    end

    def prefill_from_context
      if (project = params[:project_id].presence && Project.kept.friendly.find_by_friendly_id(params[:project_id]))
        @record.body = [project.title, project.summary].compact_blank.join("\n\n")
        @record.link = "#{settings.public_base_url}/proyectos/#{project.slug}"
        @record.media_item = project.visible_media.find(&:photo?)
      elsif (item = params[:media_item_id].presence && MediaItem.kept.friendly.find_by_friendly_id(params[:media_item_id]))
        @record.media_item = item
        @record.body = [item.title, item.description].compact_blank.join("\n\n")
      end
    end

    def load_media_library
      @library = MediaItem.visible.photos.order(created_at: :desc).limit(60)
    end

    def record_params
      params.require(:social_post).permit(:body, :link, :image, :remove_image, :media_item_id,
                                          :to_facebook, :to_instagram, :scheduled_at)
    end
  end
end
