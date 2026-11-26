ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "stringio"

class IntelligenceContentTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  Reply = Data.define(:code, :headers, :chunks) do
    def [](name) = headers[name]
    def content_type = self["Content-Type"]
    def content_length = self["Content-Length"]
    def read_body(&block) = chunks.each(&block)
  end

  setup do
    @now = 0
    @wire = []
    @log = StringIO.new
    @registration = ContinuumAuth::Registration.new("intelligence.harvj.com", "consumer", "fixture-secret", nil)
    @client = IntelligenceContent.new(registration: @registration, clock: -> { @now }, logger: Logger.new(@log))
    @client.define_singleton_method(:transport) { self }
    wire = @wire
    @client.define_singleton_method(:request) do |request, &read|
      reply = wire.shift.call(request)
      read.call(reply)
    end
  end

  test "authenticates only the exact content endpoint and follows publish edit rename withdrawal and 304" do
    enqueue(page(regions: {}), etag: '"empty"') do |request|
      assert_equal "GET", request.method
      assert_equal "/internal/v1/content/pages/continuum/intelligence", request.path
      assert_equal "auth.harvj.com", request.uri.host
      assert_equal "https", request.uri.scheme
      assert_equal "Basic #{Base64.strict_encode64('consumer:fixture-secret')}", request["Authorization"]
      assert_equal "application/json", request["Accept"]
      assert_nil request["Cookie"]
      assert_nil request["If-None-Match"]
    end
    refresh
    assert_nil cached.markdown

    enqueue(page(markdown: "> A fixture."), etag: '"published"') { |req| assert_equal '"empty"', req["If-None-Match"] }
    refresh
    assert_equal "quote", cached.presentation
    assert_equal "> A fixture.", cached.markdown

    enqueue(page(markdown: "Edited **prose**.", presentation: "prose", title: "Natural Intelligence"), etag: '"edited"')
    refresh
    assert_equal "Natural Intelligence", cached.title
    assert_equal "Edited **prose**.", cached.markdown
    @now = 90
    enqueue(nil, code: 304, etag: '"edited"') { |req| assert_equal '"edited"', req["If-None-Match"] }
    refresh
    assert_equal 90, cached.verified_at
    enqueue(page(regions: {}, title: "Natural Intelligence"), etag: '"withdrawn"')
    refresh
    assert_nil cached.markdown
    assert_equal "Natural Intelligence", cached.title
  end

  test "retains the last verified representation for five minutes then fails open" do
    enqueue(page, etag: '"good"')
    refresh
    @now = 100
    enqueue(nil, code: 503, extra: { "Retry-After" => "180" })
    assert_equal 180, refresh
    assert_equal "Intelligence", cached.title
    @now = 299
    @wire << ->(_) { raise Timeout::Error, "do not log this" }
    refresh
    assert cached
    @now = 300
    assert_nil cached
    assert_not_includes @log.string, "do not log this"
    assert_not_includes @log.string, "fixture-secret"
  end

  test "rejects invalid representations, ignores unknown regions and clears on authorization loss" do
    enqueue(page, etag: '"good"')
    refresh
    [
      [page.merge(application: "other"), '"other"'],
      [page.merge(title: " "), '"bad-title"'],
      [page.merge(regions: []), '"bad-regions"'],
      [page, "unquoted"],
      ["x" * (64 * 1024 + 1), '"oversized"']
    ].each do |body, etag|
      enqueue(body, etag:)
      refresh
      assert_equal '"good"', cached.etag
    end
    enqueue(page(regions: { unknown: {}, main: { presentation: "unknown" } }), etag: '"unknown"')
    refresh
    assert_nil cached.markdown

    [401, 403, 404].each do |status|
      enqueue(page, etag: '"good"')
      refresh
      enqueue(nil, code: status)
      refresh
      assert_nil cached
    end
    assert_raises(ArgumentError) { IntelligenceContent.new(registration: @registration.with(host: "network.harvj.com"), logger: Logger.new(@log)) }
  end

  test "initial lookup starts a single asynchronous fetch and returns immediately" do
    entered = Queue.new
    release = Queue.new
    @wire << lambda do |_request|
      entered << true
      release.pop
      Reply.new("503", {}, [])
    end
    assert_nil @client.current
    Timeout.timeout(1) { entered.pop }
    assert_nil @client.current
    assert_empty @wire
  ensure
    release << true
    @client.instance_variable_get(:@worker)&.kill
  end

  private

  def page(markdown: "> A fixture.", presentation: "quote", title: "Intelligence", regions: nil)
    { application: "continuum", page: "intelligence", application_title: "Continuum", title:,
      regions: regions || { main: { presentation:, markdown: } } }
  end

  def enqueue(body, code: 200, etag: nil, extra: {}, &inspect)
    @wire << lambda do |request|
      inspect&.call(request)
      source = body.is_a?(Hash) ? body.to_json : body
      Reply.new(code.to_s, { "Content-Type" => "application/json", "ETag" => etag }.merge(extra), [source].compact)
    end
  end

  def refresh = @client.send(:refresh)

  def cached
    # Suppress the scheduling loop for transport tests driven by the fake clock.
    @client.instance_variable_set(:@worker, true)
    @client.current
  end
end
