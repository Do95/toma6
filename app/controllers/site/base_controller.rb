module Site
  class BaseController < ApplicationController
    layout "site"
    helper_method :nav_sections, :page_heading

    private

    # Menú: las secciones del inicio marcadas "en el menú", en su orden.
    def nav_sections
      @nav_sections ||= begin
        Section.ensure_home_defaults!(settings)
        Section.home.visible.in_nav.ordered.to_a
      end
    end

    # Título y bajada de las páginas internas: salen de su sección del inicio.
    def page_heading(kind, fallback_title, fallback_lead = nil)
      section = Section.home_kind(kind)
      [section&.title.presence || fallback_title, section&.lead.presence || fallback_lead]
    end
  end
end
