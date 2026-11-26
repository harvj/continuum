require "net/http"
require "time"
require "timeout"

# The cache and refresher belong to the single Continuum web process.
class IntelligenceContent
  HOST = "intelligence.harvj.com".freeze
  PAGE = URI("#{ContinuumAuth::ISSUER}/internal/v1/content/pages/continuum/intelligence").freeze
  MAX_BODY = 64 * 1024
  MAX_AGE = 300
  ETAG = /\A"[\x21\x23-\x7e]{1,256}"\z/
  Page = Data.define(:title, :presentation, :markdown, :etag, :verified_at)
  InvalidResponse = Class.new(StandardError)

  def initialize(registration:, logger:, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
    raise ArgumentError unless registration.host == HOST && registration.callback == "https://#{HOST}/auth/callback"

    @registration = registration
    @logger = logger
    @clock = clock
    @lock = Mutex.new
  end

  def current
    @lock.synchronize do
      @worker ||= Thread.new do
        loop do
          delay = refresh
          sleep [delay, rand(55..65)].max
        end
      end
      @page if @page && @clock.call - @page.verified_at < MAX_AGE
    end
  end

  private

  def refresh
    old = @lock.synchronize { @page }
    request = Net::HTTP::Get.new(PAGE)
    request["Accept"] = "application/json"
    request["If-None-Match"] = old.etag if old
    request.basic_auth(@registration.id, @registration.secret)

    delay = 0
    Timeout.timeout(3) do
      transport.request(request) do |response|
        case response.code.to_i
        when 200
          publish(parse(response))
          @logger.info("continuum.intelligence content: representation verified")
        when 304
          raise InvalidResponse unless old && (!response["ETag"] || response["ETag"] == old.etag)
          publish(old.with(verified_at: @clock.call))
        when 401, 403, 404
          publish(nil)
          diagnostic("access or page unavailable (#{response.code})")
        when 429, 503
          delay = [60, retry_after(response["Retry-After"])].max
          diagnostic("refresh deferred (#{response.code})")
        when 400, 405, 412
          diagnostic("integration error (#{response.code})")
        else
          diagnostic("unexpected response (#{response.code})")
        end
        read_body(response) unless response.code == "200"
      end
    end
    delay
  rescue InvalidResponse, JSON::ParserError
    diagnostic("invalid response")
    60
  rescue Timeout::Error, IOError, SocketError, SystemCallError, OpenSSL::SSL::SSLError, Net::ProtocolError
    diagnostic("transport failure")
    60
  end

  def transport
    Net::HTTP.new(PAGE.host, PAGE.port, nil).tap do |http|
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = 1
      http.read_timeout = 3
      http.max_retries = 0
    end
  end

  def parse(response)
    etag = response["ETag"]
    raise InvalidResponse unless ETAG.match?(etag) && response.content_type == "application/json"
    data = JSON.parse(read_body(response), allow_duplicate_key: false)
    unless data.is_a?(Hash) && data.values_at("application", "page") == %w[continuum intelligence] &&
        valid_title?(data["application_title"]) && valid_title?(data["title"]) && data["regions"].is_a?(Hash)
      raise InvalidResponse
    end

    regions = data["regions"]
    main = regions["main"]
    if regions.key?("main") && !(main.is_a?(Hash) && main["presentation"].is_a?(String))
      raise InvalidResponse
    end

    if main && %w[quote prose].include?(main["presentation"])
      markdown = main["markdown"]
      raise InvalidResponse unless markdown.is_a?(String) && markdown.valid_encoding? && !markdown.strip.empty?
      presentation = main["presentation"]
    end
    Page.new(data["title"].freeze, presentation&.freeze, markdown&.freeze, etag.freeze, @clock.call)
  end

  def read_body(response)
    raise InvalidResponse if response.content_length.to_i > MAX_BODY

    body = +""
    response.read_body do |chunk|
      raise InvalidResponse if body.bytesize + chunk.bytesize > MAX_BODY
      body << chunk
    end
    body
  end

  def valid_title?(title)
    title.is_a?(String) && title.valid_encoding? && !title.include?("\0") &&
      !title.strip.empty? && title.length <= 120
  end

  def publish(page)
    @lock.synchronize { @page = page }
  end

  def retry_after(value)
    return 0 if value.nil?
    return value.to_i if /\A\d{1,10}\z/.match?(value)

    [(Time.httpdate(value) - Time.now).ceil, 0].max
  rescue ArgumentError
    0
  end

  def diagnostic(message)
    @logger.warn("continuum.intelligence content: #{message}")
  end
end
