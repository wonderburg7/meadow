"""Paths and loaded modules shared by the workflow test files.

Split out of test_source_checks.py on 17 Sep 2026 so a failing test is read
from a file about its own subject, not one 1,800-line file."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import tomllib
import unittest


SOURCE_CHECKS_PATH = Path(__file__).with_name("source_checks.py")
CHECK_DOCS_PATH = SOURCE_CHECKS_PATH.parent.parent / "tools" / "check_docs.py"
# check_docs.py imports it to read the plans' queue blocks, so a fixture
# repository with one and not the other cannot run its own checks.
BACKLOG_PATH = SOURCE_CHECKS_PATH.parent.parent / "tools" / "backlog.py"
SLICE_PATH = SOURCE_CHECKS_PATH.parent.parent / "tools" / "slice.ps1"
VERIFY_PATH = SOURCE_CHECKS_PATH.parent.parent / "tools" / "verify.ps1"
# slice.ps1 and verify.ps1 both dot-source this, so a fixture repository that
# omits it runs a script that cannot start.
DIAGNOSTICS_PATH = SOURCE_CHECKS_PATH.parent.parent / "tools" / "diagnostics.ps1"
CODEX_CONFIG_PATH = SOURCE_CHECKS_PATH.parent.parent / ".codex" / "config.toml"
CODEX_RULES_PATH = (
    SOURCE_CHECKS_PATH.parent.parent / ".codex" / "rules" / "meadow.rules"
)
ENVIRONMENT_CONFIG_PATH = (
    SOURCE_CHECKS_PATH.parent.parent / ".codex" / "environment.toml"
)
PREREQUISITES_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "prerequisites.gd"
SETTINGS_CATALOGUE_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "settings_catalogue.gd"
CHALLENGE_RUNNER_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "challenge_runner.gd"
CHALLENGE_STAGES_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "challenge_stages.gd"
BEE_FORAGING_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "bee_foraging.gd"
SPEC = importlib.util.spec_from_file_location("source_checks", SOURCE_CHECKS_PATH)
source_checks = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(source_checks)
CHECK_DOCS_SPEC = importlib.util.spec_from_file_location("check_docs", CHECK_DOCS_PATH)
check_docs = importlib.util.module_from_spec(CHECK_DOCS_SPEC)
CHECK_DOCS_SPEC.loader.exec_module(check_docs)


def windows_powershell():
    """The shell slice.ps1 and verify.ps1 run under in use: Windows
    PowerShell 5.1, whatever else is on PATH. Codex puts its own pwsh 7
    first on PATH, so `which("pwsh") or which("powershell")` drove the
    lifecycle suite under pwsh 7 for Codex and 5.1 for Claude: a pass in one
    lane said nothing about the other (ruled out, but only after a rerun,
    while diagnosing FB-3 on 27 Sep 2026). test_codex_environment already
    chose 5.1 this way. pwsh is the fallback only where 5.1 does not exist."""
    system = Path(os.environ.get("SystemRoot", r"C:\Windows")) / "System32" / "WindowsPowerShell" / "v1.0" / "powershell.exe"
    if system.is_file():
        return str(system)
    return shutil.which("powershell") or shutil.which("pwsh")
