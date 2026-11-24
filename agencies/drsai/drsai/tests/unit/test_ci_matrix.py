"""Tests for the CI matrix cost/coverage contract in .github/workflows/ci.yml.

drsai is a PRIVATE repo, so Actions minutes are billed with per-OS multipliers
(Linux x1, Windows x2, macOS x10). A static 3x3 test matrix billed 39
Linux-equivalent multiplier units on every pull request for a package with no
compiled component. The matrix is therefore trigger-dependent: Linux-only on
pull requests, the full 3x3 on push-to-main, `v*` tags, and the weekly
schedule.

These tests pin BOTH halves of that trade: the cost reduction, and the
guarantees that make it safe to take — the release gate still needs the full
matrix, no supported Python is dropped, and `fail-fast: false` survives.
"""

from pathlib import Path

import pytest
import yaml

WORKFLOW = Path(__file__).resolve().parents[3] / ".github" / "workflows" / "ci.yml"

# Every Python in `requires-python = ">=3.10"` / the pyproject classifiers.
SUPPORTED_PYTHONS = ["3.10", "3.11", "3.12"]
FULL_OS_MATRIX = ["ubuntu-latest", "macos-latest", "windows-latest"]


@pytest.fixture(scope="module")
def workflow():
    """The parsed CI workflow."""
    assert WORKFLOW.is_file(), f"CI workflow not found at {WORKFLOW}"
    return yaml.safe_load(WORKFLOW.read_text())


@pytest.fixture(scope="module")
def triggers(workflow):
    """The `on:` block. PyYAML parses the bare key `on` as the boolean True."""
    return workflow.get("on", workflow.get(True))


@pytest.fixture(scope="module")
def matrix(workflow):
    return workflow["jobs"]["test"]["strategy"]["matrix"]


class TestMatrixCost:
    """Pull requests must not bill the macOS/Windows legs."""

    def test_os_axis_is_trigger_dependent(self, matrix):
        """The OS axis is an expression keyed on the triggering event.

        A plain list here means every pull request bills all nine legs again.
        """
        os_axis = matrix["os"]
        assert isinstance(os_axis, str), (
            "matrix.os must be a trigger-dependent expression, not a static "
            f"list -- found {os_axis!r}"
        )
        assert "github.event_name" in os_axis
        assert "pull_request" in os_axis

    def test_os_expression_is_a_single_line(self, matrix):
        """A folded block that kept its newlines is a silently broken expression."""
        assert "\n" not in matrix["os"]

    def test_pull_requests_run_linux_only(self, matrix):
        """The pull-request branch of the expression selects Linux alone."""
        os_axis = matrix["os"]
        assert "fromJSON('[\"ubuntu-latest\"]')" in os_axis
        pr_branch = os_axis.split("||")[0]
        for slow in ("macos-latest", "windows-latest"):
            assert (
                slow not in pr_branch
            ), f"{slow} is billed on pull requests (macOS is x10 on a private repo)"

    def test_other_triggers_keep_the_full_matrix(self, matrix):
        """Push, tags, and the schedule still exercise all three platforms."""
        fallback = matrix["os"].split("||")[1]
        for os_name in FULL_OS_MATRIX:
            assert os_name in fallback, f"{os_name} dropped from the non-PR matrix"


class TestCoverageIsNotWeakened:
    """The cost cut must not quietly become a coverage cut."""

    def test_every_supported_python_is_tested(self, matrix):
        assert matrix["python-version"] == SUPPORTED_PYTHONS

    def test_fail_fast_is_disabled(self, workflow):
        """One red leg must not cancel the others -- we need the full picture."""
        assert workflow["jobs"]["test"]["strategy"]["fail-fast"] is False

    def test_weekly_full_matrix_sweep_exists(self, triggers):
        """A schedule catches platform-only regressions during quiet periods."""
        schedule = triggers.get("schedule")
        if schedule:
            assert any(entry.get("cron") for entry in schedule)
            return
        # The schedule is deliberately paused while Actions billing is blocked
        # (bamr87/bamr87#268): a scheduled run would be refused without running.
        # Accept that only while the pause is documented in the workflow, the
        # weekly cron is kept ready to uncomment, and a manual trigger remains.
        text = WORKFLOW.read_text()
        assert "bamr87/bamr87#268" in text, (
            "no schedule: trigger and no documented billing pause -- "
            "nothing sweeps the full matrix"
        )
        assert "#   - cron:" in text, "paused schedule lost its cron line"
        assert "workflow_dispatch" in triggers, "paused schedule needs a manual trigger"

    def test_push_and_tag_triggers_survive(self, triggers):
        push = triggers["push"]
        assert "main" in push["branches"]
        assert "v*" in push["tags"]


class TestReleaseGate:
    """`publish` must still require everything it required before."""

    def test_publish_needs_the_full_matrix(self, workflow):
        needs = workflow["jobs"]["publish"]["needs"]
        assert "test" in needs and "lint" in needs

    def test_publish_is_tag_gated(self, workflow):
        """Tag pushes are `push` events, so the full 3x3 gates every release."""
        assert workflow["jobs"]["publish"]["if"] == "startsWith(github.ref, 'refs/tags/v')"
