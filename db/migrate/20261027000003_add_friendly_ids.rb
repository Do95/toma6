# Ninguna URL del panel lleva el id numérico: cada registro tiene un identificador
# amigable (friendly_id).
#   - Con texto: slug a partir del título (preguntas, planes, pasos, valores, medios, secciones).
#   - Sin texto propio: un código al azar (historial de correos y de actividad, publicaciones, ubicaciones).
#   - Cotizaciones y solicitudes usan su número; enlaces, su código; plantillas, su clave; usuarios, su código.
class AddFriendlyIds < ActiveRecord::Migration[8.0]
  TITLED = { plans: "title", faqs: "question", process_steps: "title", about_values: "title", media_items: "title",
             sections: "COALESCE(NULLIF(title, ''), kind)" }.freeze
  RANDOM = %i[email_logs activity_logs social_posts media_placements].freeze

  def up
    (TITLED.keys + RANDOM).each { |table| add_column table, :slug, :string }

    RANDOM.each do |table|
      execute "UPDATE #{table} SET slug = substr(md5(random()::text || id::text), 1, 12) WHERE slug IS NULL"
    end

    TITLED.each do |table, source|
      taken = Set.new
      select_rows("SELECT id, #{source} FROM #{table} ORDER BY id").each do |id, text|
        base = I18n.transliterate(text.to_s).parameterize.first(80).delete_suffix("-").presence || "item"
        slug = base
        n = 1
        slug = "#{base}-#{n += 1}" while taken.include?(slug)
        taken << slug
        execute "UPDATE #{table} SET slug = #{quote(slug)} WHERE id = #{id.to_i}"
      end
    end

    (TITLED.keys + RANDOM).each do |table|
      change_column_null table, :slug, false
      add_index table, :slug, unique: true
    end

    backfill_numbers
  end

  def down
    (TITLED.keys + RANDOM).each do |table|
      remove_index table, :slug
      remove_column table, :slug
    end
  end

  private

  # Solicitudes y cotizaciones viejas sin número: reciben el siguiente correlativo
  def backfill_numbers
    settings = SiteSetting.current
    QuoteRequest.unscoped.where(number: nil).order(:id).find_each do |request|
      QuoteRequest.transaction do
        request.update_columns(number: DocumentNumber.next!(QuoteRequest, prefix: settings.request_prefix.presence || "SOL", with_year: true, digits: 4))
      end
    end
    Quote.unscoped.where(number: nil).order(:id).find_each { |quote| quote.update_columns(number: Quote.next_number(settings)) }
  end
end
