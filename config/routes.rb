Rails.application.routes.draw do
  devise_for :users, path: "admin/cuenta",
                     path_names: { sign_in: "ingresar", sign_out: "salir", password: "clave" },
                     skip: [:registrations]

  get "up" => "rails/health#show", as: :rails_health_check

  # ---------- Sitio público ----------
  scope module: :site do
    root "pages#home"
    get "proyectos", to: "projects#index", as: :projects
    get "proyectos/:slug", to: "projects#show", as: :project
    get "galeria", to: "gallery#index", as: :gallery
    get "galeria/albumes/:slug", to: "gallery#album", as: :album
    get "servicios", to: "services#index", as: :services
    get "cotizar", to: redirect("/servicios#cotizador")
    post "cotizar", to: "quote_requests#create", as: :quote_requests
    get "cotizar/enviada", to: "quote_requests#thanks", as: :quote_request_thanks
    get "l/:code", to: "short_links#show", as: :short_link_redirect
    get "c/:token", to: "public_quotes#show", as: :public_quote
    get "c/:token/pdf", to: "public_quotes#pdf", as: :public_quote_pdf
    patch "c/:token/aceptar", to: "public_quotes#accept", as: :accept_public_quote
    get "sitemap.xml", to: "seo#sitemap", defaults: { format: :xml }, as: :sitemap
    get "robots.txt", to: "seo#robots", defaults: { format: :text }, as: :robots
  end

  # ---------- Panel de administración ----------
  namespace :admin do
    root "dashboard#show"

    resource :site_content, only: %i[edit update], path: "contenido"
    resource :settings, only: %i[edit update], path: "ajustes"
    resource :profile, only: %i[edit update], path: "perfil"

    resources :services, path: "servicios"
    resources :projects, path: "proyectos" do
      member { get :share }
    end
    resources :albums, path: "albumes"
    resources :media_items, path: "medios" do
      collection do
        post :bulk_create
        patch :bulk_update
        get :library, path: "biblioteca"
      end
      member { get :share }
    end
    resources :sections, path: "secciones" do
      member do
        post :duplicate
        patch :toggle
      end
      collection { post :restore_defaults, path: "restaurar" }
    end
    resources :media_placements, path: "ubicaciones", only: %i[create destroy] do
      member { patch :cover }
    end
    resources :categories, path: "categorias", except: :show
    resources :process_steps, path: "proceso", except: :show
    resources :faqs, path: "preguntas", except: :show
    resources :about_values, path: "valores", except: :show

    resources :quote_requests, path: "solicitudes", only: %i[index show update destroy] do
      member { post :convert }
    end
    resources :quotes, path: "cotizaciones" do
      member do
        get :pdf
        post :duplicate
        post :deliver
        patch :status
      end
    end

    resources :short_links, path: "enlaces" do
      member { get :qr }
      collection do
        get :preview
        get :template, path: "plantilla"
        match :import, path: "importar", via: %i[get post]
      end
    end
    resources :social_posts, path: "publicaciones" do
      member { post :publish_now }
    end
    resource :integration, only: %i[show update destroy], path: "integraciones" do
      get :connect
      get :callback
      post :select_page
    end

    resources :email_templates, path: "correos/plantillas", only: %i[index edit update] do
      member do
        get :preview
        post :test
        post :restore
      end
    end
    resources :email_logs, path: "correos", only: %i[index show] do
      member do
        get :body
        post :retry
      end
      collection { post :retry_failed }
    end
    resources :users, path: "usuarios"
    resources :activity_logs, path: "actividad", only: %i[index show]
    delete "eliminar/:type/:id", to: "destroys#destroy", as: :hard_delete
    get "papelera", to: "trash#index", as: :trash
    post "papelera/restaurar", to: "trash#restore", as: :restore_trash
    delete "papelera/eliminar", to: "trash#purge", as: :purge_trash
    delete "papelera/vaciar", to: "trash#empty", as: :empty_trash
    patch "ordenar", to: "sortings#update", as: :sort

    authenticate :user, ->(u) { u.admin? } do
      mount GoodJob::Engine => "tareas", as: :good_job if Rails.configuration.x.jobs_enabled
    end
  end
end
