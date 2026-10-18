module Site
  class PagesController < BaseController
    def home
      Section.ensure_home_defaults!(settings)
      @sections = Section.home.visible.ordered.includes(:album).to_a
      kinds = @sections.map(&:kind)
      @services = Service.visible.ordered if kinds.include?("services")
      @projects = Project.visible.featured.ordered.limit(8) if kinds.include?("work")
      if kinds.include?("gallery_teaser")
        @teaser = MediaItem.visible.in_gallery.where(featured: true).ordered.limit(9).to_a
        @teaser = MediaItem.visible.in_gallery.ordered.limit(9).to_a if @teaser.size < 6
        @gallery_count = MediaItem.visible.in_gallery.group(:kind).count
      end
      @values = AboutValue.visible.ordered if kinds.include?("about")
      @steps = ProcessStep.visible.ordered if kinds.include?("process")
      @faqs = Faq.visible.ordered if kinds.include?("faq")
    end
  end
end
