class CreateSiteSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :site_settings do |t|
      # Identidad
      t.string :site_name, null: false, default: "toma6"
      t.string :legal_name
      t.string :logo
      t.string :wordmark
      t.string :og_image
      t.string :pdf_logo

      # Portada
      t.string :hero_claim
      t.text :hero_subtitle
      t.string :hero_primary_cta
      t.string :hero_secondary_cta
      t.string :ticker_primary
      t.string :ticker_secondary
      t.text :manifesto

      # Nosotros
      t.string :about_title
      t.text :about_lead
      t.text :about_body
      t.text :about_closing

      # Títulos e introducciones de cada sección
      t.string :services_title
      t.text :services_intro
      t.string :work_title
      t.text :work_intro
      t.string :gallery_title
      t.text :gallery_intro
      t.string :process_title
      t.text :process_intro
      t.string :faq_title
      t.text :faq_intro
      t.string :quote_title
      t.text :quote_intro
      t.string :contact_title
      t.text :contact_intro

      # Contacto y redes
      t.string :contact_email
      t.string :notification_email
      t.string :whatsapp_number
      t.string :phone
      t.string :address
      t.string :city
      t.string :country, default: "El Salvador"
      t.string :instagram_url
      t.string :facebook_url
      t.string :tiktok_url
      t.string :youtube_url

      # SEO
      t.string :site_url
      t.string :seo_title
      t.text :seo_description
      t.string :google_analytics_id
      t.text :footer_text

      # Cotizaciones
      t.string :currency_symbol, null: false, default: "$"
      t.string :currency_code, null: false, default: "USD"
      t.string :tax_name, null: false, default: "IVA"
      t.decimal :tax_rate, precision: 5, scale: 2, null: false, default: 13
      t.boolean :estimator_shows_tax, null: false, default: false
      t.decimal :bundle_discount_percent, precision: 5, scale: 2, null: false, default: 0
      t.integer :bundle_min_services, null: false, default: 2
      t.text :estimator_disclaimer
      t.string :quote_prefix, null: false, default: "COT"
      t.integer :quote_validity_days, null: false, default: 15
      t.text :quote_default_notes
      t.text :quote_default_terms
      t.text :quote_payment_info

      # Sistema
      t.integer :trash_retention_days, null: false, default: 15
      t.datetime :last_trash_purge_at

      t.bigint :updated_by_id
      t.timestamps
    end
    add_foreign_key :site_settings, :users, column: :updated_by_id, on_delete: :nullify
  end
end
