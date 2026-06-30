"""Split static/Audio/Ambient/blah-blah.wav into individual clips."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "static" / "Audio" / "Ambient" / "blah-blah.wav"
OUTPUT_DIR = ROOT / "static" / "Audio" / "Ambient"

SILENCE_GAP_MS = 250
MIN_CLIP_SEC = 0.4
PAD_SEC = 0.04
RMS_WINDOW_SEC = 0.01
THRESHOLD_RATIO = 0.06
TARGET_PEAK = 7500


def load_mono_samples(path: Path) -> tuple[list[float], int, int, int, bytes]:
    with wave.open(str(path), "rb") as w:
        channels = w.getnchannels()
        rate = w.getframerate()
        sample_width = w.getsampwidth()
        raw = w.readframes(w.getnframes())

    if sample_width != 2:
        raise ValueError(f"Expected 16-bit PCM, got width {sample_width}")

    frame_count = len(raw) // (sample_width * channels)
    samples: list[float] = []
    for i in range(frame_count):
        total = 0.0
        for ch in range(channels):
            offset = (i * channels + ch) * sample_width
            total += struct.unpack_from("<h", raw, offset)[0]
        samples.append(total / channels)

    return samples, rate, channels, sample_width, raw


def detect_segments(samples: list[float], rate: int) -> list[tuple[float, float]]:
    window = max(1, int(rate * RMS_WINDOW_SEC))
    rms: list[float] = []
    for i in range(0, len(samples) - window, window):
        chunk = samples[i : i + window]
        rms.append(math.sqrt(sum(x * x for x in chunk) / len(chunk)))

    threshold = max(rms) * THRESHOLD_RATIO
    active = [value > threshold for value in rms]
    min_gap = max(1, int(SILENCE_GAP_MS / (RMS_WINDOW_SEC * 1000)))

    regions: list[tuple[int, int]] = []
    in_region = False
    start = 0
    gap = 0
    for i, is_active in enumerate(active):
        if is_active:
            if not in_region:
                start = i
                in_region = True
            gap = 0
        elif in_region:
            gap += 1
            if gap >= min_gap:
                regions.append((start, i - gap))
                in_region = False
                gap = 0

    if in_region:
        regions.append((start, len(active) - gap))

    total_sec = len(samples) / rate
    segments: list[tuple[float, float]] = []
    for start_idx, end_idx in regions:
        start_sec = start_idx * window / rate
        end_sec = end_idx * window / rate
        duration = end_sec - start_sec
        if duration < MIN_CLIP_SEC:
            continue
        segments.append(
            (max(0.0, start_sec - PAD_SEC), min(total_sec, end_sec + PAD_SEC))
        )

    return segments


def write_clip(
    raw: bytes,
    channels: int,
    sample_width: int,
    rate: int,
    start_sec: float,
    end_sec: float,
    output_path: Path,
) -> float:
    frame_size = sample_width * channels
    start_frame = int(start_sec * rate)
    end_frame = int(end_sec * rate)
    start_byte = start_frame * frame_size
    end_byte = end_frame * frame_size
    clip_raw = raw[start_byte:end_byte]
    clip_raw = normalize_pcm(clip_raw, channels, sample_width, TARGET_PEAK)

    with wave.open(str(output_path), "wb") as out:
        out.setnchannels(channels)
        out.setsampwidth(sample_width)
        out.setframerate(rate)
        out.writeframes(clip_raw)

    return end_sec - start_sec


def normalize_pcm(raw: bytes, channels: int, sample_width: int, target_peak: int) -> bytes:
    if sample_width != 2:
        return raw

    frame_size = sample_width * channels
    peak = 0
    for i in range(0, len(raw) - frame_size + 1, frame_size):
        for ch in range(channels):
            value = abs(struct.unpack_from("<h", raw, i + ch * sample_width)[0])
            if value > peak:
                peak = value

    if peak == 0:
        return raw

    scale = target_peak / peak
    out = bytearray(len(raw))
    for i in range(0, len(raw) - frame_size + 1, frame_size):
        for ch in range(channels):
            offset = i + ch * sample_width
            value = struct.unpack_from("<h", raw, offset)[0]
            scaled = int(max(-32768, min(32767, round(value * scale))))
            struct.pack_into("<h", out, offset, scaled)

    return bytes(out)


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing source file: {SOURCE}")

    samples, rate, channels, sample_width, raw = load_mono_samples(SOURCE)
    segments = detect_segments(samples, rate)
    if not segments:
        raise SystemExit("No speech segments detected.")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for old in OUTPUT_DIR.glob("Blah_Blah_*.wav"):
        old.unlink()

    print(f"Writing {len(segments)} clips to {OUTPUT_DIR}")
    for index, (start_sec, end_sec) in enumerate(segments, start=1):
        duration = end_sec - start_sec
        duration_label = max(1, int(round(duration)))
        filename = f"Blah_Blah_{index:02d}_{duration_label}sec.wav"
        output_path = OUTPUT_DIR / filename
        actual_duration = write_clip(
            raw, channels, sample_width, rate, start_sec, end_sec, output_path
        )
        print(f"  {filename} ({actual_duration:.2f}s)")


if __name__ == "__main__":
    main()
