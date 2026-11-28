require "redcarpet"

module IntelligenceContentHelper
  def intelligence_markdown(source)
    renderer = Redcarpet::Render::HTML.new(filter_html: true, no_images: true, no_links: true)
    Redcarpet::Markdown.new(renderer).render(source).html_safe
  end
end
