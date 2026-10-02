## Learned Patterns & Edge Cases

> High-density heuristics distilled from verified production execution.
> Hard-Cap: Max 10 rules. Clean, zero-bloat standard.

### Pattern #1: Retina Coordinate Normalization
- **Condition**: Operating macOS GUI on high-DPI Retina displays
- **Action**: Read backingScaleFactor via AppKit and normalize coordinates in [0..1000]
- **Avoid**: Passing raw physical pixel coordinates directly to CoreGraphics

### Pattern #2: Non-Blocking FIFO Stream
- **Condition**: Establishing IPC FIFO connection with native Swift HUD
- **Action**: Open FIFO with continuous O_RDWR descriptor in Swift to maintain permanent open stream
- **Avoid**: Relying on standard open-close cycles that hang the Python writer

### Pattern #3: Zero-Cost Local OCR Preference
- **Condition**: Target text or button is visible on macOS screen
- **Action**: Dispatch to local Apple Silicon Neural OCR (VNRecognizeTextRequest) or ax-scanner
- **Avoid**: Sending unnecessary screenshot payloads to external cloud VLMs

