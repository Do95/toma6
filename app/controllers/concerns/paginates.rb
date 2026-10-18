module Paginates
  extend ActiveSupport::Concern

  included do
    helper_method :pagination
  end

  Pagination = Struct.new(:page, :per, :total_count) do
    def total_pages = [(total_count / per.to_f).ceil, 1].max
    def prev_page = page > 1 ? page - 1 : nil
    def next_page = page < total_pages ? page + 1 : nil
    def range_label
      return "0 resultados" if total_count.zero?
      first = (page - 1) * per + 1
      last = [page * per, total_count].min
      "#{first}–#{last} de #{total_count}"
    end
  end

  private

  def paginate(scope, per: 30)
    page = [params[:page].to_i, 1].max
    total = scope.count(:all)
    total = total.size if total.is_a?(Hash) # consultas agrupadas
    @pagination = Pagination.new(page, per, total)
    scope.limit(per).offset((page - 1) * per)
  end

  def pagination = @pagination
end
