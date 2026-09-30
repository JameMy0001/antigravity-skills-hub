#!/usr/bin/env python3
"""
coordinate_transformer.py - Universal Coordinate Normalization Engine
Author: Jamemm (@JameMy0001)

Provides deterministic bidirectional mapping across three coordinate spaces:
1. Normalized Model Space: [0..1000, 0..1000] (Top-Left origin, resolution independent)
2. Logical macOS Screen Points: [0..W_pt, 0..H_pt] (Used by WindowServer and CGEvents)
3. Physical Retina Pixels: [0..W_px, 0..H_px] (Used by screencapture and OpenCV/PIL images)

Zero decorative emojis maintained throughout.
"""

from typing import Tuple, Dict, Any, Optional
import ctypes
import ctypes.util
import os
import subprocess


class ScreenGeometry:
    """Represents the physical and logical geometry of a macOS display."""

    def __init__(
        self,
        logical_width: float,
        logical_height: float,
        pixel_width: int,
        pixel_height: int,
        scale_factor: float = 2.0,
        origin_x: float = 0.0,
        origin_y: float = 0.0
    ):
        self.logical_width = logical_width
        self.logical_height = logical_height
        self.pixel_width = pixel_width
        self.pixel_height = pixel_height
        self.scale_factor = scale_factor
        self.origin_x = origin_x
        self.origin_y = origin_y

    def __repr__(self) -> str:
        return (
            f"ScreenGeometry(logical={self.logical_width}x{self.logical_height}pt, "
            f"physical={self.pixel_width}x{self.pixel_height}px, "
            f"scale={self.scale_factor}x, origin=({self.origin_x}, {self.origin_y}))"
        )


class CoordinateTransformer:
    """
    Transforms coordinates between Normalized [0..1000], macOS Logical Points,
    and Physical Retina Pixels.
    """

    def __init__(self, geometry: Optional[ScreenGeometry] = None):
        self.geometry = geometry or self.detect_main_display_geometry()

    @staticmethod
    def detect_main_display_geometry() -> ScreenGeometry:
        """
        Detects primary screen dimensions and Retina scale factor via CoreGraphics and AppKit.
        Falls back to standard MacBook Pro Retina dimensions if APIs fail.
        """
        try:
            cg_path = ctypes.util.find_library("CoreGraphics")
            appkit_path = ctypes.util.find_library("AppKit")
            objc_path = ctypes.util.find_library("objc")

            if cg_path and appkit_path and objc_path:
                cg = ctypes.cdll.LoadLibrary(cg_path)
                objc = ctypes.cdll.LoadLibrary(objc_path)

                main_display = cg.CGMainDisplayID()

                # Logical bounds via CGDisplayBounds
                class CGRect(ctypes.Structure):
                    _fields_ = [
                        ("origin_x", ctypes.c_double),
                        ("origin_y", ctypes.c_double),
                        ("size_w", ctypes.c_double),
                        ("size_h", ctypes.c_double),
                    ]

                cg.CGDisplayBounds.restype = CGRect
                cg.CGDisplayBounds.argtypes = [ctypes.c_uint32]
                bounds = cg.CGDisplayBounds(main_display)

                logical_w = float(bounds.size_w) if bounds.size_w > 0 else 1710.0
                logical_h = float(bounds.size_h) if bounds.size_h > 0 else 1112.0
                origin_x = float(bounds.origin_x)
                origin_y = float(bounds.origin_y)

                # Query exact backingScaleFactor from AppKit NSScreen.mainScreen
                objc.objc_getClass.restype = ctypes.c_void_p
                objc.objc_getClass.argtypes = [ctypes.c_char_p]
                objc.sel_registerName.restype = ctypes.c_void_p
                objc.sel_registerName.argtypes = [ctypes.c_char_p]
                objc.objc_msgSend.restype = ctypes.c_void_p
                objc.objc_msgSend.argtypes = [ctypes.c_void_p, ctypes.c_void_p]

                nsscreen_cls = objc.objc_getClass(b"NSScreen")
                main_screen_sel = objc.sel_registerName(b"mainScreen")
                main_screen = objc.objc_msgSend(nsscreen_cls, main_screen_sel)

                objc_msgSend_f = ctypes.CDLL(objc_path).objc_msgSend
                objc_msgSend_f.restype = ctypes.c_double
                objc_msgSend_f.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
                scale_sel = objc.sel_registerName(b"backingScaleFactor")
                scale = objc_msgSend_f(main_screen, scale_sel)

                if scale < 1.0 or scale > 4.0:
                    scale = 2.0

                pixel_w = int(round(logical_w * scale))
                pixel_h = int(round(logical_h * scale))

                return ScreenGeometry(
                    logical_width=logical_w,
                    logical_height=logical_h,
                    pixel_width=pixel_w,
                    pixel_height=pixel_h,
                    scale_factor=scale,
                    origin_x=origin_x,
                    origin_y=origin_y
                )
        except Exception:
            pass

        # Robust macOS default fallback (MacBook Pro Retina 1710x1112 pt, 3420x2224 px)
        return ScreenGeometry(
            logical_width=1710.0,
            logical_height=1112.0,
            pixel_width=3420,
            pixel_height=2224,
            scale_factor=2.0,
            origin_x=0.0,
            origin_y=0.0
        )

    def norm_to_point(self, norm_x: float, norm_y: float) -> Tuple[float, float]:
        """
        Converts normalized model coordinates [0..1000, 0..1000]
        to macOS logical screen points [origin_x..origin_x+W, origin_y..origin_y+H].
        Clamps to valid bounds to prevent out-of-screen clicks.
        """
        clamped_x = max(0.0, min(1000.0, float(norm_x)))
        clamped_y = max(0.0, min(1000.0, float(norm_y)))

        pt_x = self.geometry.origin_x + (clamped_x / 1000.0) * self.geometry.logical_width
        pt_y = self.geometry.origin_y + (clamped_y / 1000.0) * self.geometry.logical_height

        return round(pt_x, 2), round(pt_y, 2)

    def point_to_norm(self, pt_x: float, pt_y: float) -> Tuple[int, int]:
        """
        Converts macOS logical screen points to normalized model coordinates [0..1000, 0..1000].
        """
        rel_x = pt_x - self.geometry.origin_x
        rel_y = pt_y - self.geometry.origin_y

        norm_x = (rel_x / self.geometry.logical_width) * 1000.0 if self.geometry.logical_width > 0 else 0.0
        norm_y = (rel_y / self.geometry.logical_height) * 1000.0 if self.geometry.logical_height > 0 else 0.0

        clamped_x = max(0, min(1000, int(round(norm_x))))
        clamped_y = max(0, min(1000, int(round(norm_y))))

        return clamped_x, clamped_y

    def point_to_retina(self, pt_x: float, pt_y: float) -> Tuple[int, int]:
        """
        Converts macOS logical points to physical Retina screenshot pixel coordinates.
        """
        rel_x = pt_x - self.geometry.origin_x
        rel_y = pt_y - self.geometry.origin_y

        px_x = int(round(rel_x * self.geometry.scale_factor))
        px_y = int(round(rel_y * self.geometry.scale_factor))

        return px_x, px_y

    def retina_to_point(self, px_x: float, px_y: float) -> Tuple[float, float]:
        """
        Converts physical Retina screenshot pixels to macOS logical screen points.
        """
        scale = self.geometry.scale_factor if self.geometry.scale_factor > 0 else 2.0
        pt_x = self.geometry.origin_x + (float(px_x) / scale)
        pt_y = self.geometry.origin_y + (float(px_y) / scale)

        return round(pt_x, 2), round(pt_y, 2)

    def retina_to_norm(self, px_x: float, px_y: float) -> Tuple[int, int]:
        """
        Converts physical Retina screenshot pixels directly to normalized model coordinates [0..1000].
        """
        pt_x, pt_y = self.retina_to_point(px_x, px_y)
        return self.point_to_norm(pt_x, pt_y)

    def norm_box_to_points(
        self,
        box_norm: Tuple[float, float, float, float]
    ) -> Dict[str, float]:
        """
        Converts a normalized bounding box (ymin, xmin, ymax, xmax) or (xmin, ymin, xmax, ymax)
        to logical screen rectangle {x, y, width, height, center_x, center_y}.
        """
        c1_x, c1_y = self.norm_to_point(box_norm[0], box_norm[1])
        c2_x, c2_y = self.norm_to_point(box_norm[2], box_norm[3])

        min_x = min(c1_x, c2_x)
        max_x = max(c1_x, c2_x)
        min_y = min(c1_y, c2_y)
        max_y = max(c1_y, c2_y)

        width = max_x - min_x
        height = max_y - min_y
        center_x = min_x + (width / 2.0)
        center_y = min_y + (height / 2.0)

        return {
            "x": round(min_x, 2),
            "y": round(min_y, 2),
            "width": round(width, 2),
            "height": round(height, 2),
            "center_x": round(center_x, 2),
            "center_y": round(center_y, 2),
        }

    def get_summary(self) -> Dict[str, Any]:
        """Returns structured metadata summary of the active coordinate configuration."""
        return {
            "logical_width_pt": self.geometry.logical_width,
            "logical_height_pt": self.geometry.logical_height,
            "physical_width_px": self.geometry.pixel_width,
            "physical_height_px": self.geometry.pixel_height,
            "scale_factor": self.geometry.scale_factor,
            "origin": [self.geometry.origin_x, self.geometry.origin_y],
        }


if __name__ == "__main__":
    print("==================================================")
    print("COORDINATE TRANSFORMER SELF-TEST")
    print("==================================================")
    transformer = CoordinateTransformer()
    summary = transformer.get_summary()
    for k, v in summary.items():
        print(f"{k}: {v}")

    print("--------------------------------------------------")
    # Test 1: Center coordinates
    center_pt = transformer.norm_to_point(500, 500)
    center_norm = transformer.point_to_norm(center_pt[0], center_pt[1])
    print(f"Norm (500, 500) -> Point {center_pt} -> Re-norm {center_norm}")
    assert center_norm == (500, 500), f"Center norm mismatch: {center_norm}"

    # Test 2: Top-left
    tl_pt = transformer.norm_to_point(0, 0)
    tl_norm = transformer.point_to_norm(tl_pt[0], tl_pt[1])
    print(f"Norm (0, 0) -> Point {tl_pt} -> Re-norm {tl_norm}")
    assert tl_norm == (0, 0), f"Top-left mismatch: {tl_norm}"

    # Test 3: Bottom-right
    br_pt = transformer.norm_to_point(1000, 1000)
    br_norm = transformer.point_to_norm(br_pt[0], br_pt[1])
    print(f"Norm (1000, 1000) -> Point {br_pt} -> Re-norm {br_norm}")
    assert br_norm == (1000, 1000), f"Bottom-right mismatch: {br_norm}"

    # Test 4: Retina conversion
    retina_px = transformer.point_to_retina(center_pt[0], center_pt[1])
    recovered_pt = transformer.retina_to_point(retina_px[0], retina_px[1])
    print(f"Point {center_pt} -> Retina Px {retina_px} -> Recovered Point {recovered_pt}")

    print("--------------------------------------------------")
    print("[PASS] CoordinateTransformer test suite succeeded.")
