# Números automáticos y correlativos (COT-2026-0001, SOL-2026-0001).
#
# - Nunca se repiten: se toma un bloqueo en PostgreSQL mientras se calcula el
#   siguiente, así dos personas guardando a la vez reciben números distintos.
# - Cuentan también los registros que están en la papelera (no se reutilizan).
# - El año en el número hace que la secuencia vuelva a 1 cada año.
class DocumentNumber
  def self.format(prefix:, sequence:, year: Date.current.year, with_year: true, digits: 4)
    "#{stem_for(prefix: prefix, with_year: with_year, year: year)}#{sequence.to_s.rjust(digits.to_i.clamp(1, 8), '0')}"
  end

  # Parte fija del número: "COT-2026-" o "COT-"
  def self.stem_for(prefix:, with_year: true, year: Date.current.year)
    [prefix.to_s.strip.upcase.presence, (year if with_year)].compact.map { |p| "#{p}-" }.join
  end

  # Debe llamarse dentro de una transacción (por ejemplo, en before_create).
  def self.next!(model, prefix:, with_year: true, digits: 4, start: 1, column: :number)
    lock!(model)
    stem = stem_for(prefix: prefix, with_year: with_year)
    used = model.unscoped.where("#{column} LIKE ?", "#{model.sanitize_sql_like(stem)}%")
                .pluck(column).filter_map { |n| n.delete_prefix(stem)[/\A(\d+)\z/, 1]&.to_i }
    sequence = [used.max.to_i + 1, start.to_i].max
    format(prefix: prefix, sequence: sequence, with_year: with_year, digits: digits)
  end

  # Ejemplo para mostrar en Ajustes
  def self.preview(prefix:, with_year:, digits:, start:)
    format(prefix: prefix, sequence: [start.to_i, 1].max, with_year: with_year, digits: digits)
  end

  def self.lock!(model)
    key = Zlib.crc32("document_number:#{model.table_name}")
    model.connection.execute("SELECT pg_advisory_xact_lock(#{key})")
  end
end
