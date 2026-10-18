module Site
  class SeoController < BaseController
    def sitemap
      @projects = Project.visible.ordered
      @albums = Album.visible.in_gallery.ordered
      render layout: false
    end

    def robots
      render plain: <<~TXT
        User-agent: *
        Disallow: /admin
        Disallow: /c/
        Allow: /

        Sitemap: #{settings.public_base_url}/sitemap.xml
      TXT
    end
  end
end
