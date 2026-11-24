ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

class ContinuumAuthTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  setup do
    @registration = ContinuumAuth::Registration.new("network.harvj.com", "client", "test-only", nil)
    @auth = ContinuumAuth.new(@registration)
  end

  test "Shell username and destinations require exact issuer client subject and grant bindings" do
    grant = "test-token"
    now = Time.current.to_i
    data = {
      "version" => "1", "iss" => ContinuumAuth::ISSUER, "aud" => @registration.id, "sub" => "verified-subject",
      "grant_binding" => Digest::SHA256.hexdigest(grant), "preferred_username" => "jim",
      "eligible_destination_ids" => %w[muzeum remote-gaming], "iat" => now, "exp" => now + 60
    }
    @auth.define_singleton_method(:introspect) do |token, options|
      raise ArgumentError unless token == grant && options == { "application_shell_version" => "1" }

      { "active" => true, "application_shell" => data }
    end
    evidence = @auth.evidence(grant, subject: "verified-subject")
    assert_equal "jim", evidence.username
    assert_equal %w[muzeum remote-gaming], evidence.destinations
    assert_nil @auth.evidence(grant, subject: "another-subject")

    { "version" => "2", "iss" => "https://elsewhere.example", "aud" => "another-client",
      "grant_binding" => "0" * 64, "preferred_username" => "Jim Harvey",
      "eligible_destination_ids" => ["muzeum", "muzeum"], "iat" => now + 5, "exp" => now }.each do |key, invalid|
      valid = data[key]
      data[key] = invalid
      assert_nil @auth.evidence(grant, subject: "verified-subject"), key
      data[key] = valid
    end
    travel_to Time.at(now + 60) do
      assert_nil @auth.evidence(grant, subject: "verified-subject")
    end
  end

  test "client revokes an access grant through Auth's JSON back channel" do
    @auth.define_singleton_method(:discovery_endpoint) { |_field, _fallback| "https://auth.harvj.com/revoke" }
    http = Net::HTTP.new("auth.harvj.com", 443)
    http.define_singleton_method(:request) do |request|
      @revocation_request = request
      Net::HTTPOK.new("1.1", "200", "OK").tap do |response|
        response.define_singleton_method(:body) { "{}" }
      end
    end

    Net::HTTP.stub(:new, http) { @auth.revoke("opaque-test-grant") }

    request = http.instance_variable_get(:@revocation_request)
    assert_equal "/revoke", request.path
    assert_equal "application/json", request["Accept"]
    assert_equal "application/json", request["Content-Type"]
    assert_equal "Basic #{Base64.strict_encode64('client:test-only')}", request["Authorization"]
    assert_equal({ "token" => "opaque-test-grant", "token_type_hint" => "access_token" }, JSON.parse(request.body))
  end

  test "client verifies a signed ID token before returning an opaque token and local deadline" do
    key = OpenSSL::PKey::RSA.generate(2048)
    kid = "test-key"
    signing = ->(claims) { JSON::JWT.new(claims).tap { |jwt| jwt.kid = kid }.sign(key, :RS256).to_s }
    now = Time.current.to_i
    claims = { iss: ContinuumAuth::ISSUER, sub: "verified-subject", aud: @registration.id,
               exp: now + 300, iat: now, nonce: "nonce" }
    token_class = Data.define(:id_token, :access_token, :expires_in)
    current_id_token = signing.call(claims)
    client = Object.new
    client.define_singleton_method(:authorization_code=) { |code| raise ArgumentError unless code == "code" }
    client.define_singleton_method(:access_token!) do |code_verifier:, client_auth_method:|
      raise ArgumentError unless code_verifier == "test-verifier" && client_auth_method == :basic

      token_class.new(current_id_token, "opaque-token", 300)
    end
    server = OpenIDConnect::Discovery::Provider::Config::Response.new({})
    server.define_singleton_method(:jwk) { |received| raise ArgumentError unless received == kid; key.public_key }
    @auth.define_singleton_method(:client) { client }
    @auth.define_singleton_method(:discovery) { server }
    attempt = Data.define(:verifier, :nonce).new("test-verifier", "nonce")
    result = @auth.exchange("code", attempt)
    assert_equal "verified-subject", result.subject
    assert_equal "opaque-token", result.grant
    assert_equal Time.at(now + 300), result.expires_at

    [{ nonce: "wrong" }, { aud: "another-client" }, { exp: now - 5 },
     { iss: "https://elsewhere.example" }, { aud: %w[client other] }].each do |change|
      current_id_token = signing.call(claims.merge(change))
      assert_raises(ContinuumAuth::Invalid, ContinuumAuth::Unavailable) { @auth.exchange("code", attempt) }
    end
    wrong_key = OpenSSL::PKey::RSA.generate(2048)
    current_id_token = JSON::JWT.new(claims).tap { |jwt| jwt.kid = kid }.sign(wrong_key, :RS256).to_s
    assert_raises(ContinuumAuth::Unavailable) { @auth.exchange("code", attempt) }
  end
end
