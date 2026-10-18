module Admin
  class AboutValuesController < ResourceController
    self.resource_class = AboutValue
    self.sortable = true

    private

    def record_params = params.require(:about_value).permit(:title, :description, :published)
  end
end
