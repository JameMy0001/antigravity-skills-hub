#!/usr/bin/env python3
"""
Antigravity CUA Bridge (Pattern B1)
Zero-Cost, Antigravity-Driven Computer Use Controller.

Enables Google Antigravity to directly perceive, ground, and actuate
macOS GUI workflows using local system tools and the persistent Swift HUD.
Zero external API costs: 100% powered by Antigravity context.
"""

import sys
import os
import time
import json
import argparse
import subprocess
import shutil
from typing import Dict, Any, List, Optional

# Add scripts directory to module path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

from coordinate_transformer import CoordinateTransformer
from accessibility_scanner import AccessibilityScannerWrapper
from codex_vision_loop import NativeInputSynthesizer

HUD_PIPE_PATH = "/tmp/cua_hud.pipe"
SCREENSHOT_PATH = "/tmp/cua_screen.png"


def ensure_hud_alive() -> bool:
    """Verifies that the persistent Mini Display HUD is running; launches if absent."""
    res = subprocess.run(["pgrep", "-f", "computer-use-hud"], capture_output=True, text=True)
    if res.returncode == 0 and res.stdout.strip():
        return True

    # Find binary
    hud_bin = shutil.which("computer-use-hud")
    if not hud_bin:
        candidate = os.path.join(os.path.dirname(current_dir), "hud", "computer-use-hud")
        if os.path.exists(candidate):
            hud_bin = candidate

    if not hud_bin or not os.path.exists(hud_bin):
        print(f"[WARN] computer-use-hud binary not found at {hud_bin}", file=sys.stderr)
        return False

    # Launch daemon
    subprocess.Popen([hud_bin], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.5)
    return True


def write_to_hud_pipe(command_line: str):
    """Writes command string to HUD named pipe."""
    if not os.path.exists(HUD_PIPE_PATH):
        return
    try:
        with open(HUD_PIPE_PATH, "w") as f:
            f.write(command_line.strip() + "\n")
    except Exception as e:
        print(f"[WARN] Failed to write to HUD pipe: {e}", file=sys.stderr)


def get_focused_app() -> str:
    """Returns the name of the currently frontmost application on macOS."""
    script = 'tell application "System Events" to get name of first process whose frontmost is true'
    try:
        res = subprocess.run(["osascript", "-e", script], capture_output=True, text=True, timeout=2)
        out = res.stdout.strip()
        return out if out else "Finder"
    except Exception:
        return "Finder"


def cmd_observe(args) -> Dict[str, Any]:
    """
    Perceives macOS desktop state:
    1. Captures full resolution screenshot to /tmp/cua_screen.png.
    2. Runs native Swift ax-scanner to extract clickable UI elements.
    3. Returns structured landmarks to Antigravity.
    """
    ensure_hud_alive()

    # Capture screenshot
    subprocess.run(["screencapture", "-x", SCREENSHOT_PATH], check=True)

    transformer = CoordinateTransformer()
    scanner = AccessibilityScannerWrapper()

    focused_app = get_focused_app()
    target_app = args.app if args.app else focused_app

    landmarks = scanner.scan(app_name=target_app, max_elements=25)
    raw_elements = [lm.to_dict() for lm in landmarks]

    # Write status to HUD
    geom = transformer.geometry
    write_to_hud_pipe(f"Antigravity Observing | Active: {focused_app}|{int(geom.logical_width/2)}|{int(geom.logical_height/2)}|0|0")

    result = {
        "status": "OK",
        "screenshot_path": SCREENSHOT_PATH,
        "focused_app": focused_app,
        "geometry": {
            "logical_width": geom.logical_width,
            "logical_height": geom.logical_height,
            "scale_factor": geom.scale_factor
        },
        "landmark_count": len(raw_elements),
        "landmarks": raw_elements
    }
    return result


def cmd_click(args) -> Dict[str, Any]:
    """
    Acts upon GUI via normalized or logical point click:
    1. Glides ghost cursor to target position with ripple animation.
    2. Synthesizes native CoreGraphics mouse event.
    """
    ensure_hud_alive()
    transformer = CoordinateTransformer()
    synthesizer = NativeInputSynthesizer()

    # Determine coordinate space
    if args.norm or (0.0 <= args.x <= 1000.0 and 0.0 <= args.y <= 1000.0 and args.norm is not False):
        pt_x, pt_y = transformer.norm_to_point(args.x, args.y)
        norm_x, norm_y = args.x, args.y
    else:
        pt_x, pt_y = args.x, args.y
        norm_x, norm_y = transformer.point_to_norm(pt_x, pt_y)

    thought = args.thought or f"Clicking ({int(norm_x)}, {int(norm_y)})"
    click_count = 2 if args.double else 1

    # Send to HUD pipe for visual glide & ripple
    write_to_hud_pipe(f"{thought}|{int(pt_x)}|{int(pt_y)}|1|0")
    time.sleep(0.15)

    # Synthesize native OS event
    synthesizer.click(pt_x, pt_y, button=args.button, click_count=click_count)

    return {
        "status": "OK",
        "action": "click",
        "point": [round(pt_x, 1), round(pt_y, 1)],
        "norm": [int(norm_x), int(norm_y)],
        "button": args.button,
        "clicks": click_count
    }


def cmd_ocr_click(args) -> Dict[str, Any]:
    """Directly triggers Apple Silicon Neural Vision OCR grounding for on-screen text."""
    ensure_hud_alive()
    thought = args.thought or f"OCR Searching: '{args.query}'"
    write_to_hud_pipe(f"ocr_click|{args.query}")
    return {
        "status": "OK",
        "action": "ocr_click",
        "query": args.query,
        "thought": thought
    }


def cmd_type(args) -> Dict[str, Any]:
    """Types text string into currently focused application."""
    ensure_hud_alive()
    synthesizer = NativeInputSynthesizer()
    thought = args.thought or f"Typing: '{args.text}'"

    # Send status to HUD
    write_to_hud_pipe(f"{thought}|0|0|0|0")

    synthesizer.type_text(args.text)

    if args.enter:
        time.sleep(0.1)
        synthesizer.press_key("return")

    return {
        "status": "OK",
        "action": "type",
        "text": args.text,
        "appended_enter": bool(args.enter)
    }


def cmd_press_key(args) -> Dict[str, Any]:
    """Presses key combination."""
    ensure_hud_alive()
    synthesizer = NativeInputSynthesizer()
    thought = args.thought or f"Pressing Key: {args.key}"

    write_to_hud_pipe(f"{thought}|0|0|0|0")
    synthesizer.press_key(args.key)

    return {
        "status": "OK",
        "action": "press_key",
        "key": args.key
    }


def cmd_scroll(args) -> Dict[str, Any]:
    """Scrolls active window."""
    ensure_hud_alive()
    synthesizer = NativeInputSynthesizer()
    thought = args.thought or f"Scrolling {args.direction}"

    write_to_hud_pipe(f"{thought}|0|0|0|0")

    direction_val = args.amount if args.direction.lower() == "up" else -args.amount
    if synthesizer.cg:
        scroll_ev = synthesizer.cg.CGEventCreateScrollWheelEvent(None, 0, 1, int(direction_val))
        synthesizer.cg.CGEventPost(0, scroll_ev)

    return {
        "status": "OK",
        "action": "scroll",
        "direction": args.direction,
        "amount": args.amount
    }


def cmd_done(args) -> Dict[str, Any]:
    """Signals task completion, updates HUD, and hides cursor overlay."""
    ensure_hud_alive()
    thought = args.thought or "Task Complete"
    write_to_hud_pipe(f"Antigravity Complete | {thought}|0|0|0|1")
    time.sleep(0.2)
    write_to_hud_pipe("hide_cursor")

    return {
        "status": "OK",
        "action": "done",
        "thought": thought
    }


def main():
    parser = argparse.ArgumentParser(description="Antigravity CUA Bridge (Pattern B1)")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # observe
    p_obs = subparsers.add_parser("observe", help="Inspect screen and UI landmarks")
    p_obs.add_argument("--app", type=str, default=None, help="Filter for specific application")

    # click
    p_click = subparsers.add_parser("click", help="Click at coordinate")
    p_click.add_argument("--x", type=float, required=True, help="X coordinate (norm 0..1000 or points)")
    p_click.add_argument("--y", type=float, required=True, help="Y coordinate (norm 0..1000 or points)")
    p_click.add_argument("--norm", action="store_true", default=True, help="Coordinates are normalized [0..1000]")
    p_click.add_argument("--button", type=str, default="left", choices=["left", "right"])
    p_click.add_argument("--double", action="store_true", help="Perform double click")
    p_click.add_argument("--thought", type=str, default=None, help="Reasoning description for HUD status")

    # ocr_click
    p_ocr = subparsers.add_parser("ocr_click", help="Click by OCR text search")
    p_ocr.add_argument("--query", type=str, required=True, help="Text to search and click")
    p_ocr.add_argument("--thought", type=str, default=None, help="Reasoning description for HUD status")

    # type
    p_type = subparsers.add_parser("type", help="Type string into active application")
    p_type.add_argument("--text", type=str, required=True, help="Text to type")
    p_type.add_argument("--enter", action="store_true", help="Press return after typing")
    p_type.add_argument("--thought", type=str, default=None, help="Reasoning description for HUD status")

    # press_key
    p_key = subparsers.add_parser("press_key", help="Press key or shortcut")
    p_key.add_argument("--key", type=str, required=True, help="Key name (return, escape, cmd+c, etc.)")
    p_key.add_argument("--thought", type=str, default=None, help="Reasoning description for HUD status")

    # scroll
    p_scroll = subparsers.add_parser("scroll", help="Scroll active window")
    p_scroll.add_argument("--direction", type=str, default="down", choices=["up", "down"])
    p_scroll.add_argument("--amount", type=int, default=5, help="Scroll lines")
    p_scroll.add_argument("--thought", type=str, default=None, help="Reasoning description for HUD status")

    # done
    p_done = subparsers.add_parser("done", help="Complete task")
    p_done.add_argument("--thought", type=str, default=None, help="Completion summary")

    args = parser.parse_args()

    handlers = {
        "observe": cmd_observe,
        "click": cmd_click,
        "ocr_click": cmd_ocr_click,
        "type": cmd_type,
        "press_key": cmd_press_key,
        "scroll": cmd_scroll,
        "done": cmd_done
    }

    handler = handlers.get(args.command)
    if not handler:
        parser.print_help()
        sys.exit(1)

    res = handler(args)
    print(json.dumps(res, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
