module Admin
  class FaqsController < ResourceController
    self.resource_class = Faq
    self.sortable = true

    private

    def record_params = params.require(:faq).permit(:question, :answer, :published)
  end
end
