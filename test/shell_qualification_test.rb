ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "digest"

# Run explicitly with SHELL_QUALIFICATION_INPUTS pointing to a directory
# containing v1 and v2 bundles authenticated by Infrastructure's verifier.
if ENV["SHELL_QUALIFICATION_INPUTS"]
  class ShellQualificationTest < ActionDispatch::IntegrationTest
    self.use_transactional_tests = false

    DIGESTS = {
      "v1" => {
        "conformance.json" => "321234fa59f2110e94e47896e22c82a0f03b635cf477762b41329630fb1acd78",
        "application-shell-registry.json" => "06f064e98025a06d195c76654fade82f5976aa2c1b946fb600052098814b360e"
      },
      "v2" => {
        "conformance.json" => "8efa16791c0af1f3a96047d7d4180ac3607b333ba34bef2acc1dfcebd8bfb944",
        "application-shell-registry.json" => "fc62e66b0b34ff2d2e2da3ac96797059068b1573562b8ec8007f0dbd5508227b"
      }
    }.freeze

    DIGESTS.each_key do |baseline|
      test "#{baseline} signed fixtures preserve anonymous shell and the Library registry destination" do
        fixtures = verified_json(baseline, "conformance.json")
        registry = verified_json(baseline, "application-shell-registry.json").fetch("applications")
        seed_order = fixtures.dig("registry_cases", "SH-04", "seed_order")
        assert_equal seed_order, registry.map { |entry| entry.fetch("id") }
        library = registry.find { |entry| entry.fetch("id") == "continuum" }
        assert_equal "Library", library.fetch("name")
        credit = fixtures.dig("baseline_cases", "SH-07", "credit")
        credit_url = fixtures.dig("baseline_cases", "SH-07", "credit_url")

        LandingController::SECTIONS.each do |section|
          host! "#{section}.harvj.com"
          get "/"
          assert_response :success
          assert_select "nav a[href='#{library.fetch('canonical_url')}']", text: library.fetch("name")
          registry.reject { |entry| entry == library }.each do |entry|
            assert_select "header a[href='#{entry.fetch('canonical_url')}']", count: 0
          end
          assert_select "header a[href='/login'], header details, header button", count: 0
          assert_select "footer a[href='#{credit_url}']", text: credit
          assert_select "footer .release-version", text: "Continuum v#{ContinuumVersion.read}"
        end
      end
    end

    private

    def verified_json(baseline, name)
      bytes = File.binread(File.join(ENV.fetch("SHELL_QUALIFICATION_INPUTS"), baseline, name))
      assert_equal DIGESTS.fetch(baseline).fetch(name), Digest::SHA256.hexdigest(bytes)
      JSON.parse(bytes)
    end
  end
end
