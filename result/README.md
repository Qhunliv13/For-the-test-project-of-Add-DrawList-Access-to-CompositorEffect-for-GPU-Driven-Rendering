# Benchmark Results

This directory contains automatically generated benchmark test results.

## File Naming Convention

```
YYYYMMDD_HHMMSS_HardwareName_SpeedupX.txt
```

**Examples:**
- `20251016_214500_IntelR_IrisR_Xe_Graphics_7170x.txt`
- `20251016_215000_NVIDIA_GeForce_RTX_4090_12000x.txt`

## Test Configuration

- **Test Objects:** 20,000 spheres (1,920,000 vertices)
- **Color:** Pure blue (0, 0, 1) for all objects
- **Frames Sampled:** 60 frames average
- **VSync:** Enabled (60 FPS cap)

## Running the Benchmark

1. Open `benchmark_scene.tscn` in Godot Editor
2. Run the scene (F5)
3. **Important:** Keep the mode at "BOTH PIPELINES" (default)
4. Wait for 60+ frames (~10-15 seconds at 5-6 FPS)
5. Results will be automatically saved when complete

## Result Format

```
GPU-Driven Rendering Benchmark Results
======================================================================

Test Date: YYYY-MM-DD HH:MM:SS
Hardware: GPU_Name
Test Objects: 20,000 spheres (1,920,000 vertices)

----------------------------------------------------------------------
Results (Average of 60 frames):
----------------------------------------------------------------------

Old Pipeline (CPU-driven):
  Time per frame: XXX.XXX ms
  Actual FPS: XX.X (VSync limited)

New Pipeline (GPU-driven):
  Time per frame: X.XXX ms
  Actual FPS: 60.0 (VSync limited)

Performance Improvement:
  Speedup: XXXX.XXx
  Time reduction: XX.XX%

======================================================================
```

## Notes

- Results are only saved when **both** pipelines have valid data
- If you see "⚠️ Cannot save results", make sure you're in "BOTH PIPELINES" mode
- Press SPACE to cycle through modes (OLD → NEW → BOTH)
- The benchmark automatically detects your GPU hardware

