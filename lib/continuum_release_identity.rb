require "base64"
require "digest"
require "find"
require "json"
require "openssl"
require "time"
require_relative "continuum_version"

module ContinuumReleaseIdentity
  class Invalid < StandardError; end

  COMMIT = /\A[0-9a-f]{40}\z/
  DIGEST = /\A[0-9a-f]{64}\z/
  BINDING = ".continuum-release.json".freeze
  GENERATED = %w[.bundle vendor/bundle log tmp storage].freeze
  MAX_RECORD = 2 * 1024 * 1024
  IDENTITY_FIELDS = %w[schema_version application target_version source_sha artifact_sha256 kind].freeze

  def self.require!(condition, message)
    raise Invalid, message unless condition
  end

  def self.key(path)
    value = OpenSSL::PKey.read(File.binread(path))
    require!(value.oid == "ED25519", "Release trust requires an Ed25519 key")
    value
  end

  def self.seal(data, key)
    payload = JSON.generate(data)
    JSON.generate("payload" => payload, "signature" => Base64.strict_encode64(key.sign(nil, payload))) + "\n"
  end

  def self.read(path, key)
    raw = File.binread(path, MAX_RECORD + 1)
    require!(raw.bytesize <= MAX_RECORD, "Release record exceeds its size limit")
    envelope = JSON.parse(raw, allow_duplicate_key: false)
    fields!(envelope, %w[payload signature])
    payload, signature = envelope.values_at("payload", "signature")
    require!(payload.is_a?(String) && signature.is_a?(String), "Invalid signed release record")
    require!(key.verify(nil, Base64.strict_decode64(signature), payload), "Invalid release signature")
    JSON.parse(payload, allow_duplicate_key: false)
  rescue JSON::ParserError, ArgumentError, OpenSSL::PKey::PKeyError => error
    raise Invalid, "Malformed signed release record (#{error.class})"
  end

  def self.fields!(record, fields)
    require!(record.is_a?(Hash) && record.keys.sort == fields.sort, "Unexpected release record fields")
  end

  def self.identity!(record, kind = nil)
    fields!(record, IDENTITY_FIELDS + (record.is_a?(Hash) && record["kind"] == "candidate" ? ["candidate_number"] : []))
    actual = record["kind"]
    require!(record["schema_version"].eql?(1) && record["application"] == "continuum" &&
      %w[development candidate].include?(actual) && (!kind || actual == kind) &&
      record["source_sha"].is_a?(String) && COMMIT.match?(record["source_sha"]) &&
      record["artifact_sha256"].is_a?(String) && DIGEST.match?(record["artifact_sha256"]) &&
      record["target_version"].is_a?(String) && ContinuumVersion::FORMAT.match?(record["target_version"]) &&
      !record["target_version"].end_with?("\n"), "Invalid exact-artifact identity")
    number = record["candidate_number"]
    require!(actual != "candidate" || (number.is_a?(Integer) && number.positive?), "Invalid candidate number")
    record
  end

  def self.timestamp(value)
    require!(value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/), "Invalid release timestamp")
    time = Time.iso8601(value)
    require!(time.utc.iso8601 == value, "Noncanonical release timestamp")
    time
  rescue ArgumentError
    raise Invalid, "Invalid release timestamp"
  end

  def self.reference!(value)
    require!(value.is_a?(String) && value.length <= 512 && value.match?(/\S/), "Missing immutable evidence reference")
  end

  def self.receipt!(record, now:)
    fields!(record, %w[schema_version kind candidate final_version acceptance_ref publication_ref accepted_at published_at verified_at])
    candidate = identity!(record["candidate"], "candidate")
    require!(record["schema_version"].eql?(1) && record["kind"] == "publication" &&
      record["final_version"] == "v#{candidate.fetch('target_version')}", "Incorrect final version")
    reference!(record["acceptance_ref"])
    reference!(record["publication_ref"])
    accepted, published, verified = record.values_at("accepted_at", "published_at", "verified_at").map { |value| timestamp(value) }
    require!(accepted <= published && published <= verified && verified <= now, "Invalid release evidence chronology")
    record
  end

  # Bind the unpacked source as well as the exact archive. Build products,
  # operational state and the detached binding live outside the source digest.
  def self.tree_digest(root)
    digest = Digest::SHA256.new
    Find.find(root) do |path|
      next if path == root

      relative = path.delete_prefix("#{root}/")
      next if relative == BINDING
      Find.prune if GENERATED.include?(relative)
      stat = File.lstat(path)
      next if stat.directory?

      require!(stat.file?, "Executable release source must contain regular files")
      digest.update(JSON.generate([relative, stat.mode & 0o111, Digest::SHA256.file(path).hexdigest]) + "\n")
    end
    digest.hexdigest
  end

  class Running
    attr_reader :identity

    def initialize(root:, store:, trust_key:, packaged_version:, clock: -> { Time.now }, logger: nil)
      @root = File.realpath(root)
      @store = File.realpath(store)
      @key = ContinuumReleaseIdentity.key(trust_key)
      @clock = clock
      @logger = logger
      @mutex = Mutex.new
      binding = ContinuumReleaseIdentity.read(File.join(@root, BINDING), @key)
      ContinuumReleaseIdentity.fields!(binding, %w[schema_version kind path tree_sha256 identity])
      @identity = ContinuumReleaseIdentity.identity!(binding["identity"]).transform_values(&:freeze).freeze
      ContinuumReleaseIdentity.require!(binding["schema_version"].eql?(1) && binding["kind"] == "launch" &&
        binding["path"] == @root && @identity["target_version"] == packaged_version &&
        binding["tree_sha256"] == ContinuumReleaseIdentity.tree_digest(@root), "Release tree does not match its launch binding")
      version = @identity.fetch("target_version")
      @initial = @identity["kind"] == "development" ? "v#{version}-dev" : "v#{version}-rc.#{@identity.fetch('candidate_number')}"
      @receipt = File.join(@store, "published", "#{version}.json") if @identity["kind"] == "candidate"
    end

    def label
      return @initial unless @receipt

      @mutex.synchronize do
        return @published if @published

        begin
          receipt = ContinuumReleaseIdentity.receipt!(ContinuumReleaseIdentity.read(@receipt, @key), now: @clock.call)
          ContinuumReleaseIdentity.require!(receipt["candidate"] == @identity, "Publication receipt belongs to another artifact")
          @published = receipt.fetch("final_version").freeze
        rescue Errno::ENOENT
          @initial
        rescue Invalid, SystemCallError, IOError => error
          @logger&.warn("Continuum release receipt rejected: #{error.message}") unless @last_error == error.message
          @last_error = error.message
          @initial
        end
      end
    end
  end
end
