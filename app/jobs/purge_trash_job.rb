class PurgeTrashJob < ApplicationJob
  queue_as :default

  def perform
    result = TrashPurger.call
    Rails.logger.info("[PurgeTrashJob] #{result.total} registros eliminados definitivamente: #{result.counts}")
  end
end
