# Borra definitivamente (con sus archivos) los registros que llevan en la
# papelera más días que los configurados en Ajustes.
class TrashPurger
  Result = Struct.new(:counts, :total, keyword_init: true)

  def self.call(...) = new(...).call

  def initialize(older_than: nil, everything: false)
    @cutoff = everything ? Time.current : (older_than || SiteSetting.current.trash_retention_days.days.ago)
  end

  def call
    counts = Hash.new(0)
    SoftDeletable::MODELS.each do |name|
      model = name.constantize
      model.trashed.where("deleted_at <= ?", @cutoff).find_each do |record|
        label = record.display_name
        ActivityLog.record!(record, "purge", { "registro" => [label, nil] })
        record.destroy!
        counts[model.model_name.human(count: 2)] += 1
      rescue ActiveRecord::RecordNotFound
        next # ya se eliminó en cascada
      rescue StandardError => e
        Rails.logger.error("[TrashPurger] #{name}##{record.id}: #{e.message}")
      end
    end
    SiteSetting.current.update_columns(last_trash_purge_at: Time.current)
    Result.new(counts: counts, total: counts.values.sum)
  end
end
