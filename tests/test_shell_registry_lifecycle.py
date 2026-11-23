"""Opt-in SH-09 integration with Infrastructure's verifier and test publisher."""

import importlib.util
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import unittest


CHECKOUT = os.environ.get("CONTINUUM_INFRA_QUALIFICATION_ROOT")
ROOT = Path(__file__).resolve().parents[1]
READER = """
require_relative "./config/environment"
registry = ShellRegistry.new(ARGV.fetch(0))
STDIN.each_line do |line|
  puts JSON.generate(registry.destinations(JSON.parse(line)).pluck("id"))
  STDOUT.flush
end
"""


@unittest.skipUnless(CHECKOUT, "Provide the reviewed Infrastructure qualification archive")
class ShellRegistryLifecycleTest(unittest.TestCase):
    def setUp(self):
        path = Path(CHECKOUT) / "tests/test_application_shell_gate.py"
        spec = importlib.util.spec_from_file_location("reviewed_infrastructure_gate_tests", path)
        self.infrastructure = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.infrastructure)
        # Use the reviewed test publisher with the current production baseline
        # as the starting version. All signatures use disposable keys.
        self.infrastructure.VERSION = "1.3.0"
        self.fixture = self.infrastructure.GateTests()
        self.addCleanup(self.fixture.doCleanups)
        self.fixture.setUp()
        self.cache = self.fixture.workspace / "runtime-registry.json"
        self.keys = [self.fixture.publisher_public]

    def start_reader(self):
        process = subprocess.Popen(
            ["bundle", "exec", "ruby", "-e", READER, str(self.cache)],
            cwd=ROOT, env={**os.environ, "RAILS_ENV": "test"},
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True,
        )

        def stop():
            process.stdin.close()
            try:
                process.wait(timeout=10)
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait()
                process.stdout.close()

        self.addCleanup(stop)
        return process

    def destinations(self, process, ids):
        process.stdin.write(json.dumps(ids) + "\n")
        process.stdin.flush()
        return json.loads(process.stdout.readline())

    def refresh(self, fetch=None, now=None):
        infra = self.infrastructure
        return infra.refresh(self.cache, fetch or self.fixture.fetch, self.keys,
                             clock=lambda: infra.NOW if now is None else now)

    def test_signed_refresh_expiry_outage_restart_recovery_and_rollback(self):
        infra = self.infrastructure
        grants = ["continuum-engine", "continuum", "remote-gaming", "muzeum"]
        full = ["muzeum", "remote-gaming", "continuum-engine"]
        withdrawn = ["muzeum", "remote-gaming"]
        self.fixture.release = self.fixture.publication("1.3.0", 1, name="initial")
        initial = self.fixture.release
        running = self.start_reader()
        self.assertEqual(self.destinations(running, grants), [])

        self.assertEqual(self.refresh()["sequence"], 1)
        self.assertEqual(self.destinations(running, grants), full)
        self.assertEqual(stat.S_IMODE(self.cache.stat().st_mode), 0o600)
        cached = self.cache.read_bytes()

        with self.assertRaisesRegex(infra.GateError, "expired"):
            self.refresh(now=infra.NOW + 86400)

        def unavailable(_path):
            raise infra.GateError("publisher unavailable")

        with self.assertRaisesRegex(infra.GateError, "publisher unavailable"):
            self.refresh(fetch=unavailable)
        self.assertEqual(self.cache.read_bytes(), cached)
        restarted = self.start_reader()
        self.assertEqual(self.destinations(restarted, grants), full)
        # No fresh Auth evidence means no destinations, regardless of cache age.
        self.assertEqual(self.destinations(restarted, []), [])

        self.fixture.release = self.fixture.publication("1.3.1", 2, name="withdrawal")
        self.assertEqual(self.refresh()["sequence"], 2)
        self.assertEqual(self.destinations(running, grants), withdrawn)
        self.assertEqual(self.destinations(restarted, grants), withdrawn)
        cached = self.cache.read_bytes()

        self.fixture.release = initial
        with self.assertRaisesRegex(infra.GateError, "replay"):
            self.refresh()
        self.assertEqual(self.cache.read_bytes(), cached)
        self.assertEqual(self.destinations(self.start_reader(), grants), withdrawn)

        self.fixture.release = self.fixture.publication("1.3.0", 3, name="version-rollback")
        with self.assertRaisesRegex(infra.GateError, "replay"):
            self.refresh()
        self.assertEqual(self.cache.read_bytes(), cached)
        self.assertEqual(self.destinations(running, grants), withdrawn)
