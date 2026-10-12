import os
import subprocess
import tempfile
import unittest
from pathlib import Path

BIN_DIR = Path(__file__).resolve().parents[2] / "bin"
SCRIPT = BIN_DIR / "executable_update-agents"
if not SCRIPT.is_file():
    SCRIPT = BIN_DIR / "update-agents"
AGENTS = ("claude", "codex", "pi", "opencode", "grok")


class UpdateAgentsTest(unittest.TestCase):
    def run_script(self, installed=AGENTS, args=(), fail="", source=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            log = root / "calls"
            for agent in installed:
                executable = root / agent
                executable.write_text(
                    '#!/bin/bash\n'
                    'agent=${0##*/}\n'
                    'printf "%s %s\\n" "$agent" "$*" >> "$CALL_LOG"\n'
                    '[ "$agent" != "$FAIL_AGENT" ]\n'
                )
                executable.chmod(0o755)
            result = subprocess.run(
                ["/bin/bash", str(SCRIPT), *args] if source is None else ["/bin/bash"],
                input=source,
                env={**os.environ, "PATH": directory, "CALL_LOG": str(log),
                     "FAIL_AGENT": fail},
                capture_output=True, text=True, timeout=10,
            )
            calls = log.read_text().splitlines() if log.exists() else []
            return result, calls

    def test_all_installed(self):
        result, calls = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [
            "claude update", "codex update", "pi update --self --no-approve",
            "opencode upgrade", "grok update",
        ])

    def test_missing_agents_are_skipped(self):
        result, calls = self.run_script(installed=("grok",))
        self.assertEqual(result.returncode, 0)
        self.assertEqual(calls, ["grok update"])
        self.assertEqual(result.stdout.count("[SKIP]"), 4)

    def test_failure_does_not_stop_remaining_updates(self):
        result, calls = self.run_script(fail="codex")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(len(calls), 5)
        self.assertIn("[FAIL] codex", result.stderr)
        self.assertIn("[OK] grok", result.stdout)

    def test_dry_run_does_not_invoke_updaters(self):
        result, calls = self.run_script(args=("--dry-run",))
        self.assertEqual(result.returncode, 0)
        self.assertEqual(calls, [])
        self.assertEqual(result.stdout.count("[UPDATE]"), 5)

    def test_copy_paste_runs_without_installed_script(self):
        readme = Path(__file__).with_name("README.md").read_text()
        snippet = readme.split("```bash\n", 1)[1].split("```", 1)[0]
        self.assertIn(SCRIPT.read_text(), snippet)
        result, calls = self.run_script(installed=("grok",), source=snippet)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["grok update"])
        self.assertEqual(result.stdout.count("[SKIP]"), 4)

    def test_invalid_arguments(self):
        for args in (("--unknown",), ("--dry-run", "extra")):
            result, calls = self.run_script(args=args)
            self.assertEqual(result.returncode, 2)
            self.assertEqual(calls, [])


if __name__ == "__main__":
    unittest.main()
