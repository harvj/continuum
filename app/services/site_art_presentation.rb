class SiteArtPresentation
  SHADOW = { "opacity_percent" => 0..100, "blur_px" => 0..8, "x_px" => -4..4, "y_px" => -4..4 }.freeze
  BACKING = { "opacity_percent" => 0..50 }.freeze

  def self.resolve(presentation)
    new(presentation).resolve
  end

  def initialize(presentation)
    @presentation = presentation.is_a?(Hash) ? presentation : {}
  end

  def resolve
    flat = treatment(@presentation).freeze
    regions = @presentation["regions"]
    regions = {} unless regions.is_a?(Hash)
    {
      "default" => flat,
      "top" => flat.merge(treatment(regions["top"])).freeze,
      "bottom" => flat.merge(treatment(regions["bottom"])).freeze
    }.freeze
  end

  private

  def treatment(scope)
    return {} unless scope.is_a?(Hash)

    {
      "--art-foreground" => color(scope["foreground"]),
      "--art-text-shadow" => shadow(scope["text_shadow"]),
      "--art-backing" => backing(scope["backing"])
    }.compact.transform_values(&:freeze)
  end

  def color(value)
    value.upcase if value.is_a?(String) && value.match?(/\A#[0-9a-fA-F]{6}\z/)
  end

  def effect(value, bounds)
    return unless value.is_a?(Hash) && value.size == bounds.size + 1

    hex = color(value["color"])
    return unless hex && bounds.all? do |key, range|
      number = value[key]
      number.is_a?(Numeric) && range.cover?(number) && number == number.to_i
    end

    channels = hex.delete_prefix("#").scan(/../).map { |channel| channel.to_i(16) }
    "rgb(#{channels.join(' ')} / #{value.fetch('opacity_percent').to_i}%)"
  end

  def shadow(value)
    rgba = effect(value, SHADOW)
    return unless rgba
    return "none" if value.fetch("opacity_percent").zero?

    lengths = value.values_at("x_px", "y_px", "blur_px").map { |length| "#{length.to_i}px" }
    "#{lengths.join(' ')} #{rgba}"
  end

  def backing(value)
    rgba = effect(value, BACKING)
    return unless rgba

    value.fetch("opacity_percent").zero? ? "transparent" : rgba
  end
end
