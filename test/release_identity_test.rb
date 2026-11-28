ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "tmpdir"
require "open3"

class ReleaseIdentityTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false
  Release = ContinuumReleaseIdentity
  COMMAND = File.expand_path("../bin/release-identity", __dir__)

  setup do
    @root = Pathname(Dir.mktmpdir)
    @repo = @root.join("source").tap(&:mkdir)
    @store = @root.join("store").tap(&:mkdir)
    @config = Rails.application.config.x
    @original = @config.release_identity
    @keys = %i[release acceptance publication].to_h do |name|
      key = OpenSSL::PKey.generate_key("ED25519")
      @root.join("#{name}.key").write(key.private_to_pem, perm: 0o600)
      @root.join("#{name}.pub").write(key.public_to_pem)
      [name, key]
    end
    @env = {
      "CONTINUUM_RELEASE_SIGNING_KEY" => @root.join("release.key").to_s,
      "CONTINUUM_ACCEPTANCE_TRUST_KEY" => @root.join("acceptance.pub").to_s,
      "CONTINUUM_PUBLICATION_TRUST_KEY" => @root.join("publication.pub").to_s
    }
    git("init", "-q")
    @root_version = "0.2.0"
    @repo.join("VERSION").write("#{@root_version}\n")
    commit("Initial")
  end

  teardown do
    @config.release_identity = @original
    FileUtils.remove_entry(@root)
  end

  test "exact development and numbered artifacts remain immutable across local promotion and rollback" do
    first_sha = git("rev-parse", "HEAD").chomp
    development = prepare(first_sha, "development")
    first = prepare(first_sha)
    assert_equal first, prepare(first_sha)
    assert_equal first_sha, first.dig("identity", "source_sha")
    assert_equal Digest::SHA256.file(first.fetch("archive")).hexdigest, first.dig("identity", "artifact_sha256")
    @repo.join("marker").write("new source, same target version")
    commit("Second")
    second = prepare(git("rev-parse", "HEAD").chomp)
    assert_equal 2, second.dig("identity", "candidate_number")
    refute_equal first.dig("identity", "artifact_sha256"), second.dig("identity", "artifact_sha256")

    assert_equal "v0.2.0-dev", running(development).label
    pointer = @root.join("current")
    File.symlink(second.fetch("release"), pointer)
    active = running(second, root: pointer.to_s)
    @config.release_identity = active
    assert_footers "v0.2.0-rc.2"

    next_link = @root.join("current.next")
    File.symlink(first.fetch("release"), next_link)
    File.rename(next_link, pointer)
    assert_footers "v0.2.0-rc.2"

    acceptance, publication = evidence(second.fetch("identity"))
    bad_signature = @root.join("bad-publication.json")
    bad_signature.write(Release.seal(publication, @keys.fetch(:acceptance)))
    acceptance_path = write_evidence("acceptance", acceptance)
    refute command("publish", acceptance_path, bad_signature).last.success?
    assert_footers "v0.2.0-rc.2"

    wrong_artifact = publication.merge("artifact_sha256" => first.dig("identity", "artifact_sha256"))
    refute publish(acceptance, wrong_artifact).last.success?
    refute publish(acceptance, publication.merge("published_at" => (Time.now.utc - 120).iso8601)).last.success?
    assert_footers "v0.2.0-rc.2"

    receipt, status = publish(acceptance, publication)
    assert status.success?, receipt
    assert_equal "v0.2.0", JSON.parse(receipt)["final_version"]
    assert_footers "v0.2.0"
    saved = @store.join("published/0.2.0.json").binread
    duplicate, status = publish(acceptance, publication)
    assert status.success?, duplicate
    assert_equal receipt, duplicate

    refute publish(acceptance, publication.merge("reference" => "publication/contradictory")).last.success?
    refute publish(*evidence(first.fetch("identity"))).last.success?
    assert_equal saved, @store.join("published/0.2.0.json").binread
    assert_equal "v0.2.0", running(second).label
    assert_equal "v0.2.0-rc.1", running(first, root: pointer.to_s).label
    assert_equal "v0.2.0-dev", running(development).label
    assert_footers "v0.2.0"

    @repo.join("VERSION").write("0.1.9\n")
    commit("Different release")
    prior = prepare(git("rev-parse", "HEAD").chomp)
    prior_receipt, status = publish(*evidence(prior.fetch("identity")))
    assert status.success?, prior_receipt
    @config.release_identity = running(prior)
    assert_footers "v0.1.9"
    assert_equal "v0.2.0", active.label
  end

  test "launch verification refuses changed or copied source and retained archive corruption" do
    package = prepare(git("rev-parse", "HEAD").chomp)
    copied = @root.join("copied")
    FileUtils.cp_r(package.fetch("release"), copied)
    assert_raises(Release::Invalid) { running(package, root: copied.to_s) }

    tree_version = Pathname(package.fetch("release")).join("VERSION")
    tree_version.write("0.2.1\n")
    assert_raises(Release::Invalid) { running(package) }
    tree_version.write("0.2.0\n")

    binding = Pathname(package.fetch("release")).join(Release::BINDING)
    binding.write(binding.read.sub(/"signature":"./, '"signature":"!'))
    assert_raises(Release::Invalid) { running(package) }

    File.binwrite(package.fetch("archive"), "archive corruption")
    error, status = publish(*evidence(package.fetch("identity")))
    refute status.success?
    assert_match(/archive checksum mismatch/, error)
    assert_empty Dir.glob(@store.join("published/*"))
  end

  if ENV["SHELL_QUALIFICATION_INPUTS"]
    test "the verified v2 SH-07 sequence yields the expected running footer on all hosts" do
      bytes = File.binread(File.join(ENV.fetch("SHELL_QUALIFICATION_INPUTS"), "v2/conformance.json"))
      assert_equal "8efa16791c0af1f3a96047d7d4180ac3607b333ba34bef2acc1dfcebd8bfb944", Digest::SHA256.hexdigest(bytes)
      fixtures = JSON.parse(bytes).dig("baseline_cases", "SH-07", "release_identity")
      records = fixtures.fetch("records").transform_values do |entry|
        if entry["kind"] == "publication"
          entry.merge("candidate" => entry.fetch("candidate").merge("application" => "continuum"))
        else
          entry.merge("application" => "continuum")
        end
      end
      @store.join("published").mkdir
      packages = records.reject { |_, entry| entry["kind"] == "publication" }.to_h do |name, identity|
        root = @root.join(name).tap(&:mkdir)
        root.join("VERSION").write("#{identity.fetch('target_version')}\n")
        binding = { "schema_version" => 1, "kind" => "launch", "path" => root.realpath.to_s,
          "tree_sha256" => Release.tree_digest(root.realpath.to_s), "identity" => identity }
        root.join(Release::BINDING).write(Release.seal(binding, @keys.fetch(:release)))
        [name, { "release" => root.to_s, "identity" => identity }]
      end
      pointer = @root.join("fixture-current")
      move_pointer = ->(name) do
        File.symlink(packages.fetch(name).fetch("release"), "#{pointer}.next")
        File.rename("#{pointer}.next", pointer)
      end

      fixtures.fetch("steps").each do |event, name, label|
        temporary = nil
        case event
        when "boot", "restart"
          move_pointer.call(name)
          @config.release_identity = running(packages.fetch(name), root: pointer.to_s)
        when "pointer"
          move_pointer.call(name)
        when "verified", "unverified"
          active = @config.release_identity.identity
          record = records.fetch(name)
          target = @store.join("published/#{active.fetch('target_version')}.json")
          unless target.exist?
            key = @keys.fetch(event == "verified" ? :release : :acceptance)
            target.write(Release.seal(record, key))
            temporary = target unless event == "verified" && matching_fixture_receipt?(record, active)
          end
        when "outage"
          # No incoming record is available. The durable publication remains.
        else
          flunk "Unrecognized SH-07 event: #{event}"
        end
        assert_footers label
        temporary&.delete
      end
    end
  end

  private

  def matching_fixture_receipt?(record, active)
    Release.receipt!(record, now: Time.now)
    record["candidate"] == active
  rescue Release::Invalid
    false
  end

  def git(*arguments)
    output, status = Open3.capture2e("git", "-c", "user.name=Continuum Test",
      "-c", "user.email=test@example.com", *arguments, chdir: @repo)
    assert status.success?, output
    output
  end

  def commit(message)
    git("add", ".")
    git("commit", "-qm", message)
  end

  def command(action, *arguments)
    Open3.capture2e(@env, RbConfig.ruby, COMMAND, action, @store.to_s, *arguments.map(&:to_s), chdir: @repo)
  end

  def prepare(sha, kind = "candidate")
    output, status = command("prepare", sha, kind)
    assert status.success?, output
    JSON.parse(output)
  end

  def running(package, root: package.fetch("release"))
    Release::Running.new(root:, store: @store.to_s, trust_key: @root.join("release.pub"),
      packaged_version: package.fetch("identity").fetch("target_version"))
  end

  def evidence(candidate)
    stamp = Time.now.utc
    [{ "schema_version" => 1, "kind" => "acceptance", "candidate" => candidate,
       "reference" => "acceptance/test", "accepted_at" => (stamp - 60).iso8601 },
     { "schema_version" => 1, "kind" => "published-artifact", "candidate" => candidate,
       "reference" => "publication/test", "tag" => "v#{candidate.fetch('target_version')}", "tag_source_sha" => candidate.fetch("source_sha"),
       "artifact_sha256" => candidate.fetch("artifact_sha256"), "published_at" => (stamp - 30).iso8601 }]
  end

  def write_evidence(name, data)
    path = @root.join("#{name}.json")
    path.write(Release.seal(data, @keys.fetch(name.to_sym)))
    path
  end

  def publish(acceptance, publication)
    command("publish", write_evidence("acceptance", acceptance), write_evidence("publication", publication))
  end

  def assert_footers(label)
    LandingController::SECTIONS.each do |section|
      host! "#{section}.harvj.com"
      get "/"
      assert_response :success
      assert_select ".release-version", text: "Continuum #{label}"
    end
  end
end
