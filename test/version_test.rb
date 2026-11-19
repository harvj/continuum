require "minitest/autorun"
require "fileutils"
require "open3"
require "tmpdir"
require_relative "../lib/continuum_version"

class VersionTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_bootstrap_version_in_an_archive_without_git
    Dir.mktmpdir do |root|
      FileUtils.cp(File.join(ROOT, "VERSION"), root)
      assert_equal ContinuumVersion.read(ROOT), ContinuumVersion.read(root)
      assert_equal "0.1.0", ContinuumVersion.parse("0.1.0\n")
    end
  end

  def test_invalid_and_missing_version_fail_closed
    Dir.mktmpdir do |root|
      assert_raises(Errno::ENOENT) { ContinuumVersion.read(root) }
      %w[v0.1.0 00.1.0 0.1.0-rc1].each do |version|
        File.write(File.join(root, "VERSION"), version)
        assert_raises(ArgumentError) { ContinuumVersion.read(root) }
      end
    end
  end

  def test_version_follows_the_selected_release_through_rollback
    Dir.mktmpdir do |root|
      current = File.join(root, "current")
      old, new = %w[0.1.0 0.2.0].map do |version|
        release = File.join(root, version)
        FileUtils.mkdir_p(File.join(release, "lib"))
        FileUtils.cp(File.join(ROOT, "lib/continuum_version.rb"), File.join(release, "lib"))
        File.write(File.join(release, "VERSION"), "#{version}\n")
        release
      end
      [[old, "0.1.0"], [new, "0.2.0"], [old, "0.1.0"]].each do |release, version|
        File.symlink(release, "#{current}.next")
        File.rename("#{current}.next", current)
        output, status = Open3.capture2(RbConfig.ruby, "-r", File.join(current, "lib/continuum_version"),
                                      "-e", "puts ContinuumVersion.read")
        assert status.success?
        assert_equal version, output.chomp
      end
    end
  end

  def test_tag_is_verified_against_its_own_commit_and_expected_sha
    Dir.mktmpdir do |root|
      git(root, "init", "-q")
      File.write(File.join(root, "VERSION"), "0.1.0\n")
      git(root, "add", "VERSION")
      git(root, "commit", "-qm", "First release")
      first = git(root, "rev-parse", "HEAD").chomp
      git(root, "tag", "-am", "First release", "v0.1.0")
      git(root, "tag", "v0.9.0")
      File.write(File.join(root, "VERSION"), "0.2.0\n")
      git(root, "commit", "-qam", "Next version")
      second = git(root, "rev-parse", "HEAD").chomp
      assert verify(root, "v0.1.0", first)
      refute verify(root, "v0.1.0", second)
      refute verify(root, "v0.9.0", first)
      refute verify(root, "v0.2.0", second)
    end
  end

  private

  def git(root, *arguments)
    output, status = Open3.capture2e("git", "-c", "user.name=Continuum Test",
                                    "-c", "user.email=test@example.com", *arguments, chdir: root)
    assert status.success?, output
    output
  end

  def verify(root, *arguments)
    Open3.capture2e(RbConfig.ruby, File.join(ROOT, "bin/verify-release"), *arguments, chdir: root).last.success?
  end
end
