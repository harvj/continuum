require "bigdecimal"
require "digest"
require "json"

class SiteArt
  Asset = Data.define(:digest, :extension, :media_type, :bytes, :foreground, :presentation)
  MEDIA_TYPES = {
    ".webp" => "image/webp", ".png" => "image/png", ".jpg" => "image/jpeg",
    ".jpeg" => "image/jpeg", ".svg" => "image/svg+xml", ".gif" => "image/gif",
    ".ico" => "image/vnd.microsoft.icon"
  }.freeze
  MAX_ASSET = 25 * 1024 * 1024
  MAX_MANIFEST = 1024 * 1024

  def initialize(root, identifiers:, interval: 30, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
    @root = Pathname(root)
    @identifiers = identifiers
    @interval = interval
    @clock = clock
    @lock = Mutex.new
    @verified = {}.freeze
    @next_poll = -Float::INFINITY
  end

  def snapshot
    @lock.synchronize do
      if @clock.call >= @next_poll
        @next_poll = @clock.call + @interval
        refresh
      end
      @verified
    end
  end

  private

  def refresh
    data = File.binread(@root.join("manifest.json"), MAX_MANIFEST + 1)
    return if data.bytesize > MAX_MANIFEST

    manifest = JSON.parse(data, allow_duplicate_key: false)
    return unless manifest.is_a?(Hash) && manifest.keys.sort == %w[assets commit release schema_version] &&
      manifest["schema_version"].eql?(1) &&
      manifest["commit"].is_a?(String) && manifest["commit"].match?(/\A[0-9a-f]{40}\z/) &&
      manifest["release"].is_a?(String) && manifest["release"].match?(/\A[0-9a-f]{64}\z/) &&
      manifest["assets"].is_a?(Hash)

    payload = manifest.except("release")
    return unless Digest::SHA256.hexdigest(canonical_json(payload) + "\n") == manifest["release"]

    # Replace the snapshot only after every relevant asset is verified.
    assets = manifest.fetch("assets")
    @verified = @identifiers.filter_map do |id|
      asset = verify(id, assets[id], @verified[id])
      [id, asset] if asset
    end.to_h.freeze
  rescue JSON::ParserError, SystemCallError, IOError, ArgumentError
    # A missing or invalid snapshot keeps the last verified assets available.
  end

  def canonical_json(value)
    case value
    when Hash
      "{" + value.sort.map { |key, item| "#{canonical_json(key)}:#{canonical_json(item)}" }.join(",") + "}"
    when Array
      "[" + value.map { |item| canonical_json(item) }.join(",") + "]"
    when Float
      # Match the publisher's Python JSON spelling for numbers in optional fields.
      raise ArgumentError unless value.finite?

      mantissa, exponent = value.to_s.split("e")
      return mantissa unless exponent
      return BigDecimal(value.to_s).to_s("F") if exponent.to_i.between?(-4, 15)

      "#{mantissa.delete_suffix('.0')}e#{exponent}"
    else
      JSON.generate(value, ascii_only: true).gsub("\u007f") { '\u007f' }
    end
  end

  def verify(identifier, record, previous)
    return unless record.is_a?(Hash) &&
      record["rights"].is_a?(String) && !record["rights"].empty?

    foreground = record["foreground"]
    foreground = nil unless %w[light dark].include?(foreground)

    url, digest, size, type = record.values_at("url", "sha256", "bytes", "media_type")
    match = /\Ahttps:\/\/art\.harvj\.com\/assets\/([0-9a-f]{64})(\.[a-z]+)\z/.match(url) if url.is_a?(String)
    return unless match && digest == match[1] && type && type == MEDIA_TYPES[match[2]] &&
      size.is_a?(Integer) && size.between?(1, MAX_ASSET)

    extension = match[2]
    if identifier.end_with?("_favicon_png")
      return unless extension == ".png"
    elsif identifier.end_with?("_favicon")
      return unless %w[.svg .png].include?(extension)
    end

    presentation = SiteArtPresentation.resolve(record["presentation"])

    if previous&.extension == extension && previous.digest == digest && previous.media_type == type && previous.bytes.bytesize == size
      return previous.with(foreground: foreground.freeze, presentation: presentation)
    end

    bytes = File.binread(@root.join("assets", "#{digest}#{extension}"), size + 1)
    raise ArgumentError unless bytes.bytesize == size && Digest::SHA256.hexdigest(bytes) == digest

    Asset.new(digest.freeze, extension.freeze, type.freeze, bytes.freeze, foreground.freeze, presentation)
  end
end
