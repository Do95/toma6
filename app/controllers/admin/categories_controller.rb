module Admin
  class CategoriesController < ResourceController
    self.resource_class = Category
    self.sortable = true

    private

    def collection = super.left_joins(:media_items).group(:id).select("categories.*, COUNT(media_items.id) FILTER (WHERE media_items.deleted_at IS NULL) AS media_count")

    def record_params = params.require(:category).permit(:name, :slug)
  end
end
