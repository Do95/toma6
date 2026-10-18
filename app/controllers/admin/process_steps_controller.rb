module Admin
  class ProcessStepsController < ResourceController
    self.resource_class = ProcessStep
    self.sortable = true

    private

    def record_params = params.require(:process_step).permit(:title, :description, :published)
  end
end
