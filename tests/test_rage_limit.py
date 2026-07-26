import importlib.util
from importlib.machinery import SourceFileLoader
import sys
import unittest
from datetime import datetime, timezone
from pathlib import Path


def load_rage_limit():
    path = Path(__file__).resolve().parents[1] / "stow" / "dot-local" / "bin" / "rage-limit"
    loader = SourceFileLoader("rage_limit", str(path))
    spec = importlib.util.spec_from_loader("rage_limit", loader)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ClaudeUsageParsingTest(unittest.TestCase):
    def test_parses_legacy_top_level_claude_windows(self):
        rage_limit = load_rage_limit()
        data = {
            "five_hour": {
                "utilization": 25.0,
                "resets_at": "2026-07-07T11:10:00+00:00",
            },
            "seven_day_sonnet": {
                "utilization": 75.0,
                "resets_at": "2026-07-07T12:10:00+00:00",
            },
        }

        now = datetime(2026, 7, 7, 10, 10, tzinfo=timezone.utc)

        windows = rage_limit.parse_claude_windows(data, now=now)

        self.assertEqual(
            [(w.label, w.utilization, w.resets_in_seconds) for w in windows],
            [
                ("5-hour", 25.0, 3600),
                ("Sonnet", 75.0, 7200),
            ],
        )

    def test_parses_new_limits_response_with_scoped_weekly_model(self):
        rage_limit = load_rage_limit()
        data = {
            "five_hour": {
                "utilization": 60.0,
                "resets_at": "2026-07-07T11:10:00+00:00",
            },
            "seven_day": {
                "utilization": 43.0,
                "resets_at": "2026-07-08T05:00:00+00:00",
            },
            "limits": [
                {
                    "kind": "session",
                    "group": "session",
                    "percent": 60,
                    "resets_at": "2026-07-07T11:10:00+00:00",
                },
                {
                    "kind": "weekly_all",
                    "group": "weekly",
                    "percent": 43,
                    "resets_at": "2026-07-08T05:00:00+00:00",
                },
                {
                    "kind": "weekly_scoped",
                    "group": "weekly",
                    "percent": 17,
                    "resets_at": "2026-07-08T05:00:00+00:00",
                    "scope": {
                        "model": {
                            "id": None,
                            "display_name": "Fable",
                        },
                        "surface": None,
                    },
                },
            ],
        }

        now = datetime(2026, 7, 7, 10, 10, tzinfo=timezone.utc)

        windows = rage_limit.parse_claude_windows(data, now=now)

        self.assertEqual(
            [(w.label, w.utilization, w.resets_in_seconds) for w in windows],
            [
                ("5-hour", 60, 3600),
                ("7-day", 43, 67800),
                ("Fable", 17, 67800),
            ],
        )


class CodexUsageParsingTest(unittest.TestCase):
    def test_parses_legacy_primary_and_secondary_codex_windows(self):
        rage_limit = load_rage_limit()
        data = {
            "rate_limit": {
                "primary_window": {
                    "used_percent": 25.0,
                    "reset_after_seconds": 3600,
                },
                "secondary_window": {
                    "used_percent": 75.0,
                    "reset_after_seconds": 604800,
                },
            },
        }

        windows = rage_limit.parse_codex_windows(data)

        self.assertEqual(
            [(w.label, w.utilization, w.resets_in_seconds) for w in windows],
            [
                ("5-hour", 25.0, 3600),
                ("7-day", 75.0, 604800),
            ],
        )

    def test_labels_single_weekly_primary_codex_window_by_duration(self):
        rage_limit = load_rage_limit()
        data = {
            "rate_limit": {
                "primary_window": {
                    "used_percent": 12.0,
                    "reset_after_seconds": 604800,
                },
            },
        }

        windows = rage_limit.parse_codex_windows(data)

        self.assertEqual(
            [(w.label, w.utilization, w.resets_in_seconds) for w in windows],
            [
                ("7-day", 12.0, 604800),
            ],
        )

    def test_labels_single_weekly_primary_codex_window_with_less_than_five_days_remaining(self):
        rage_limit = load_rage_limit()
        data = {
            "rate_limit": {
                "primary_window": {
                    "used_percent": 12.0,
                    "reset_after_seconds": 4 * 86400,
                },
            },
        }

        windows = rage_limit.parse_codex_windows(data)

        self.assertEqual(
            [(w.label, w.utilization, w.resets_in_seconds) for w in windows],
            [
                ("7-day", 12.0, 4 * 86400),
            ],
        )

    def test_labels_single_short_primary_codex_window_as_five_hour(self):
        rage_limit = load_rage_limit()
        data = {
            "rate_limit": {
                "primary_window": {
                    "used_percent": 12.0,
                    "reset_after_seconds": 18000,
                },
            },
        }

        windows = rage_limit.parse_codex_windows(data)

        self.assertEqual(
            [(w.label, w.utilization, w.resets_in_seconds) for w in windows],
            [
                ("5-hour", 12.0, 18000),
            ],
        )


if __name__ == "__main__":
    unittest.main()
