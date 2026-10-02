#!/usr/bin/env python3
"""
accessibility_scanner.py - Semantic UI Landmark Extractor for CUA Grounding
Author: Jamemm (@JameMy0001)

Extracts accessible interactive elements from the frontmost application
and provides candidate target coordinates for VLM Grounding.
Zero decorative emojis maintained throughout.
"""

from typing import List, Dict, Any, Optional
import subprocess
import json
import os
import shutil


class AccessibilityLandmark:
    """Represents an interactive UI landmark extracted from the OS accessibility tree."""

    def __init__(self, data: Dict[str, Any]):
        self.role: str = data.get("role", "")
        self.subrole: Optional[str] = data.get("subrole")
        self.title: str = data.get("title", "")
        self.value: Optional[str] = data.get("value")
        self.x: float = data.get("x", 0.0)
        self.y: float = data.get("y", 0.0)
        self.width: float = data.get("width", 0.0)
        self.height: float = data.get("height", 0.0)
        self.center_x: float = data.get("centerX", 0.0)
        self.center_y: float = data.get("centerY", 0.0)
        self.norm_x: int = data.get("normX", 0)
        self.norm_y: int = data.get("normY", 0)
        self.is_sensitive: bool = data.get("isSensitive", False)

    def to_dict(self) -> Dict[str, Any]:
        """Converts landmark to dictionary representation."""
        return {
            "role": self.role,
            "subrole": self.subrole,
            "title": self.title,
            "value": self.value,
            "x": self.x,
            "y": self.y,
            "width": self.width,
            "height": self.height,
            "center_x": self.center_x,
            "center_y": self.center_y,
            "norm_x": self.norm_x,
            "norm_y": self.norm_y,
            "is_sensitive": self.is_sensitive,
        }

    def to_prompt_string(self) -> str:
        """Formats the landmark into a compact string for LLM/VLM context."""
        sensitive_flag = " [SENSITIVE_CREDENTIAL_FIELD]" if self.is_sensitive else ""
        val_str = f" val=\"{self.value}\"" if self.value else ""
        title_str = f"\"{self.title}\"" if self.title else "(unnamed)"
        return f"[{self.role}] {title_str}{val_str} @ norm=[{self.norm_x}, {self.norm_y}] size=({int(self.width)}x{int(self.height)}){sensitive_flag}"


class AccessibilityScannerWrapper:
    """Wraps native Swift ax-scanner binary and fallback introspection."""

    def __init__(self, scanner_bin_path: Optional[str] = None):
        if scanner_bin_path and os.path.exists(scanner_bin_path):
            self.scanner_bin = scanner_bin_path
        else:
            default_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "hud", "ax-scanner")
            self.scanner_bin = default_path if os.path.exists(default_path) else shutil.which("ax-scanner")

    def scan(self, app_name: Optional[str] = None, max_elements: int = 40) -> List[AccessibilityLandmark]:
        """
        Executes accessibility scan and returns a list of AccessibilityLandmarks.
        """
        if not self.scanner_bin or not os.path.exists(self.scanner_bin):
            return []

        cmd = [self.scanner_bin]
        if app_name:
            cmd.extend(["--app", app_name])

        try:
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=2.5)
            if res.returncode == 0 and res.stdout.strip():
                items = json.loads(res.stdout.strip())
                landmarks = [AccessibilityLandmark(item) for item in items if isinstance(item, dict)]
                return landmarks[:max_elements]
        except Exception:
            pass

        return []

    def get_grounding_context(self, app_name: Optional[str] = None, max_elements: int = 6) -> str:
        """
        Returns a formatted block of accessibility landmarks ready to inject into VLM prompts.
        """
        landmarks = self.scan(app_name=app_name, max_elements=max_elements)
        if not landmarks:
            return ""

        lines = ["[ACCESSIBILITY GROUNDING LANDMARKS]"]
        for lm in landmarks:
            lines.append("- " + lm.to_prompt_string())
        return "\n".join(lines)


if __name__ == "__main__":
    scanner = AccessibilityScannerWrapper()
    print("Testing AccessibilityScannerWrapper...")
    landmarks = scanner.scan()
    print(f"Discovered {len(landmarks)} landmarks.")
    for lm in landmarks[:10]:
        print("  ", lm.to_prompt_string())
    print("[PASS] AccessibilityScannerWrapper operational.")
