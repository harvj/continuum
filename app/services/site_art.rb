require "digest"
require "json"

class SiteArt
  Asset = Data.define(:digest, :media_type, :bytes)
  MEDIA_TYPES = {
    ".webp" => "image/webp", ".png" => "image/png", ".jpg" => "image/jpeg",
    ".jpeg" => "image/jpeg", ".svg" => "image/svg+xml"
  }.freeze
  MAX_ASSET = 25 * 1024 * 1024
  MAX_MANIFEST = 1024 * 1024

  def initialize(root, identifiers:, interval: 30, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
    @root = Pathname(root)
    @identifiers = identifiers
    @interval = interval
    @clock = clock
    @lock = Mutex.new
    @verified = {}
    @next_poll = -Float::INFINITY
  end

  def resolve(identifier)
    @lock.synchronize do
      if @clock.call >= @next_poll
        @next_poll = @clock.call + @interval
        refresh
      end
      @verified[identifier]
    end
  end

  private

  def refresh
    data = File.binread(@root.join("manifest.json"), MAX_MANIFEST + 1)
    return if data.bytesize > MAX_MANIFEST

    manifest = JSON.parse(data)
    return unless manifest.is_a?(Hash) && manifest["schema_version"] == 1 &&
      manifest["commit"].is_a?(String) && manifest["commit"].match?(/\A[0-9a-f]{40}\z/) &&
      manifest["release"].is_a?(String) && manifest["release"].match?(/\A[0-9a-f]{64}\z/) &&
      manifest["assets"].is_a?(Hash)

    payload = manifest.except("release")
    return unless Digest::SHA256.hexdigest(JSON.generate(sorted(payload), ascii_only: true) + "\n") == manifest["release"]

    # Replace the snapshot only after every relevant asset is verified.
    assets = manifest.fetch("assets")
    @verified = @identifiers.filter_map do |id|
      [id, verify(assets.fetch(id), @verified[id])] if assets.key?(id)
    end.to_h
  rescue JSON::ParserError, SystemCallError, IOError, ArgumentError
    # A missing or invalid snapshot keeps the last verified assets available.
  end

  def sorted(value)
    return value unless value.is_a?(Hash)

    value.sort.to_h.transform_values { |item| sorted(item) }
  end

  def verify(record, previous)
    raise ArgumentError unless record.is_a?(Hash)
    url, digest, size, type = record.values_at("url", "sha256", "bytes", "media_type")
    match = /\Ahttps:\/\/art\.harvj\.com\/assets\/([0-9a-f]{64})(\.[a-z]+)\z/.match(url) if url.is_a?(String)
    raise ArgumentError unless match && digest == match[1] && type && type == MEDIA_TYPES[match[2]] &&
      size.is_a?(Integer) && size.between?(1, MAX_ASSET)

    return previous if previous&.digest == digest && previous.media_type == type && previous.bytes.bytesize == size

    bytes = File.binread(@root.join("assets", "#{digest}#{match[2]}"), size + 1)
    raise ArgumentError unless bytes.bytesize == size && Digest::SHA256.hexdigest(bytes) == digest
    Asset.new(digest.freeze, type.freeze, bytes.freeze)
  end
end
