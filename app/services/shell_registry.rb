require "uri"

# The Infrastructure verifier owns signatures, publication ordering and atomic
# installation. The application consumes its protected local snapshot.
class ShellRegistry
  MAX_BYTES = 1024 * 1024
  EXCLUDED = %w[auth infrastructure site-art staging].freeze

  def initialize(path)
    @path = path
    @mutex = Mutex.new
    @entries = [].freeze
    @sequence = 0
  end

  def destinations(ids)
    @mutex.synchronize do
      refresh
      @entries.select { |entry| entry["id"] != "continuum" && ids.include?(entry["id"]) }
    end
  end

  private

  def refresh
    return if @path.blank?

    data = JSON.parse(File.binread(@path, MAX_BYTES + 1), allow_duplicate_key: false)
    return unless data.is_a?(Hash) && data["format_version"].eql?(1) &&
      data["sequence"].is_a?(Integer) && data["sequence"] > @sequence &&
      data["specification_version"].is_a?(String) && data["specification_version"].match?(/\A1\.\d+\.\d+\z/)

    raw = data["registry_json"]
    return unless raw.is_a?(String) && raw.bytesize <= MAX_BYTES && Digest::SHA256.hexdigest(raw) == data["registry_sha256"]

    registry = JSON.parse(raw, allow_duplicate_key: false)
    return unless registry == data["registry"] && registry.is_a?(Hash) &&
      registry["schema_version"].eql?(1) && registry["specification_version"] == data["specification_version"]

    entries = registry["applications"]
    return unless entries.is_a?(Array) && entries.size <= 64 && entries.all? { |entry| valid_entry?(entry) } &&
      entries.pluck("id").uniq.size == entries.size && entries.pluck("canonical_url").uniq.size == entries.size

    @entries = entries.map { |entry| entry.slice("id", "name", "canonical_url").transform_values(&:freeze).freeze }.freeze
    @sequence = data["sequence"]
  rescue SystemCallError, JSON::ParserError, URI::Error, IOError, ArgumentError
    # Retain the most recent valid snapshot when the publisher is unavailable.
  end

  def valid_entry?(entry)
    return false unless entry.is_a?(Hash) && entry["availability"] == "production"

    id, name, url = entry.values_at("id", "name", "canonical_url")
    return false unless id.is_a?(String) && ContinuumAuth::DESTINATION.match?(id) && !EXCLUDED.include?(id) &&
      name.is_a?(String) && name.present? && name.bytesize <= 128 && url.is_a?(String)

    uri = URI.parse(url)
    uri.scheme == "https" && uri.port == 443 && uri.host.present? && uri.path == "/" &&
      uri.userinfo.nil? && uri.query.nil? && uri.fragment.nil? &&
      !uri.host.match?(/\A(?:auth|art|infrastructure)\.harvj\.com\z|(?:\A|[.-])staging(?:[.-]|\z)/)
  end
end
