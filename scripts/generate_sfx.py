"""Synthesize the small UI/juice sound effects in static/Audio/SFX (22.05 kHz mono 16-bit)."""

import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "static", "Audio", "SFX")


def env(t, attack, decay):
    if t < attack:
        return t / attack
    return math.exp(-(t - attack) / decay)


def sine(f, t):
    return math.sin(2 * math.pi * f * t)


def square(f, t):
    return 1.0 if math.sin(2 * math.pi * f * t) >= 0 else -1.0


def write(name, samples, gain=0.8):
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = gain / peak
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in samples))


def render(duration, fn):
    return [fn(i / RATE) for i in range(int(duration * RATE))]


def lowpass(samples, alpha):
    out, y = [], 0.0
    for s in samples:
        y += alpha * (s - y)
        out.append(y)
    return out


def highpass(samples, alpha):
    out, prev_x, prev_y = [], 0.0, 0.0
    for s in samples:
        y = alpha * (prev_y + s - prev_x)
        out.append(y)
        prev_x, prev_y = s, y
    return out


def notes(seq, note_len, tail, voice):
    total = note_len * len(seq) + tail
    buf = [0.0] * int(total * RATE)
    for n, f in enumerate(seq):
        start = int(n * note_len * RATE)
        for i in range(int((note_len + tail) * RATE)):
            if start + i >= len(buf):
                break
            buf[start + i] += voice(f, i / RATE)
    return buf


def main():
    os.makedirs(OUT, exist_ok=True)
    random.seed(7)

    # Rubber stamp: thump + papery slap.
    noise = [random.uniform(-1, 1) for _ in range(int(0.3 * RATE))]
    slap = lowpass(noise, 0.35)
    write("stamp.wav", [
        0.9 * sine(70 + 60 * math.exp(-t * 40), t) * env(t, 0.002, 0.07) + 0.7 * slap[i] * env(t, 0.001, 0.025)
        for i, t in enumerate(i / RATE for i in range(len(slap)))
    ])

    bell = lambda f, t: (sine(f, t) + 0.35 * sine(f * 2.01, t) + 0.15 * sine(f * 3.02, t)) * env(t, 0.004, 0.18)
    write("success.wav", notes([523.25, 659.25, 783.99, 1046.5], 0.085, 0.45, bell), 0.7)
    write("tick.wav", notes([987.77, 1318.5], 0.06, 0.25, bell), 0.6)
    write("fanfare.wav", notes([523.25, 523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5], 0.12, 0.7, lambda f, t: (
        0.6 * square(f, t) * 0.4 + sine(f, t) + 0.3 * sine(f * 2, t)) * env(t, 0.006, 0.22)), 0.6)

    buzz = lambda f, t: (0.6 * square(f, t) + 0.4 * sine(f * 0.5, t)) * env(t, 0.004, 0.12)
    write("error.wav", lowpass(notes([196.0, 146.83], 0.13, 0.15, buzz), 0.25), 0.6)
    write("alarm.wav", lowpass(notes([220.0, 207.65, 174.61], 0.16, 0.35, buzz), 0.3), 0.65)

    noise = [random.uniform(-1, 1) for _ in range(int(0.09 * RATE))]
    swish = highpass(noise, 0.7)
    write("pickup.wav", [s * env(i / RATE, 0.015, 0.025) for i, s in enumerate(swish)], 0.45)
    noise = [random.uniform(-1, 1) for _ in range(int(0.09 * RATE))]
    thud = lowpass(noise, 0.18)
    write("drop.wav", [
        (s + 0.6 * sine(110, i / RATE)) * env(i / RATE, 0.001, 0.02) for i, s in enumerate(thud)
    ], 0.5)

    write("blip.wav", render(0.035, lambda t: square(880, t) * env(t, 0.001, 0.012)), 0.25)
    noise = [random.uniform(-1, 1) for _ in range(int(0.04 * RATE))]
    click = highpass(noise, 0.5)
    write("key.wav", [
        (s * 0.7 + 0.5 * square(1800, i / RATE)) * env(i / RATE, 0.0005, 0.006) for i, s in enumerate(click)
    ], 0.35)

    coins = [0.0] * int(0.7 * RATE)
    for k in range(7):
        start = int((k * 0.06 + random.uniform(0, 0.03)) * RATE)
        f = random.choice([2093.0, 2349.3, 2637.0, 3136.0])
        for i in range(int(0.3 * RATE)):
            if start + i < len(coins):
                t = i / RATE
                coins[start + i] += (sine(f, t) + 0.5 * sine(f * 1.5, t)) * env(t, 0.001, 0.06)
    write("coins.wav", coins, 0.5)

    noise = [random.uniform(-1, 1) for _ in range(int(0.35 * RATE))]
    out, y = [], 0.0
    for i, s in enumerate(noise):
        t = i / RATE
        alpha = 0.04 + 0.5 * math.sin(math.pi * t / 0.35)
        y += alpha * (s - y)
        out.append(y * math.sin(math.pi * t / 0.35))
    write("whoosh.wav", out, 0.4)


if __name__ == "__main__":
    main()
