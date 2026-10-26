module Site
  class BaseController < ApplicationController
    layout "site"
    helper_method :nav_sections, :page_heading, :page_cache_key

    private

    # Caché de la página: con `return if page_cached?` el controlador no hace las
    # consultas cuando ya está guardada; la vista la envuelve con `cache_page`.
    # Lo que va por content_for (título, descripción) queda afuera del bloque.
    def page_cached?(*parts)
      @page_cache_key = SiteCache.key(controller_name, action_name, *parts)
      fragment_exist?(@page_cache_key)
    end

    def page_cache_key = @page_cache_key

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
