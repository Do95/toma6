module Admin
  class DashboardController < BaseController
    def show
      @counts = {
        projects: Project.kept.count,
        media: MediaItem.kept.count,
        albums: Album.kept.count,
        services: Service.kept.count
      }
      @requests = QuoteRequest.kept.recent.limit(5) if can?(:sales)
      @quotes = Quote.kept.recent.limit(5) if can?(:sales)
      @sales = {
        open_total: Quote.kept.where(status: %w[draft sent]).sum(:total),
        accepted_month: Quote.kept.where(status: "accepted", accepted_at: Time.current.all_month).sum(:total),
        requests_month: QuoteRequest.kept.where(created_at: Time.current.all_month).count
      }
      @months = monthly_requests
      @activity = ActivityLog.recent.includes(:user).limit(12) if can?(:activity)
      @integration = Integration.meta
      @trash_count = SoftDeletable::MODELS.sum { |m| m.constantize.trashed.count }
      @next_purge = SoftDeletable::MODELS.filter_map { |m| m.constantize.trashed.minimum(:deleted_at) }.min
    end

    private

    def monthly_requests
      start = 5.months.ago.beginning_of_month
      counts = QuoteRequest.kept.where(created_at: start..).group(Arel.sql("date_trunc('month', created_at)")).count
      (0..5).map do |i|
        month = (start + i.months).to_date
        value = counts.find { |k, _| k.to_date == month }&.last.to_i
        [I18n.l(month, format: "%b"), value]
      end
    end
  end
end
