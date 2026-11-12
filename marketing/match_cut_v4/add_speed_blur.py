"""Speed pass for the Change 47 zoom match-cut (V4): reads the toolkit's composed
LootFarmer_MatchCut_Zoom_V4_en-US.mp4 and writes LootFarmer_MatchCut_Zoom_V4.mp4 with a short radial zoom blur
on the frames where the camera rushes (speed.json from make_match_v4_manifest.py).

Only the map area is touched (the dock below stays sharp). The blur is centred on the camera centre (the
zoom's own centre) and masked off inside a tall ellipse that holds the hero, the boss and its name bar, so
the combat stays crisp and the speed streaks the ground at the frame's edges. V3's mask was a 230 px circle,
which left the hero (about 380 px below the centre) partly smeared and the edge streaks faint. Its strength follows the relative zoom speed: nothing below
THRESHOLD, full at FULL, which keeps it to the few frames around each cut. Every ghost is a slightly
magnified copy (sampled inside the frame, so the edges never darken); a radial smear reads the same in
either zoom direction. The music track is copied unchanged.
"""
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
SRC = ROOT / 'store_assets/video/experiments/LootFarmer_MatchCut_Zoom_V4_en-US.mp4'
DST = ROOT / 'store_assets/video/experiments/LootFarmer_MatchCut_Zoom_V5.mp4'
W, H = 1080, 1920
# Map area height per shot: the skill row (Autumn, Spring) shortens it.
MAP_H = {'winter': 1240, 'summer': 1240, 'autumn': 1156, 'spring': 1156}
THRESHOLD, FULL = 0.60, 1.35  # relative zoom speed (1/s)
SPREAD = 0.65                 # largest scale difference between ghosts at full strength
TAPS = 11
# Mask: an ellipse around the centre, semi-axes (RX, RY) * map height / 1240; no blur inside it, full
# blur SOFT ellipse-radii out (1.0 = on the ellipse).
RX, RY, SOFT = 300.0, 540.0, 1.45


def strength(rel: float) -> float:
    return float(np.clip((abs(rel) - THRESHOLD) / (FULL - THRESHOLD), 0.0, 1.0))


def blur(frame: np.ndarray, map_h: int, s: float) -> np.ndarray:
    region = Image.fromarray(frame[:map_h])
    cx, cy = W / 2, map_h / 2
    acc = np.zeros((map_h, W, 3), np.float32)
    for i in range(TAPS):
        k = 1.0 + SPREAD * s * i / (TAPS - 1)
        # out(p) = in(c + (p - c) / k)
        m = (1 / k, 0, cx - cx / k, 0, 1 / k, cy - cy / k)
        acc += np.asarray(region.transform(region.size, Image.AFFINE, m, Image.BILINEAR), np.float32)
    acc /= TAPS
    yy, xx = np.mgrid[0:map_h, 0:W]
    f = map_h / 1240
    d = np.hypot((xx - cx) / (RX * f), (yy - cy) / (RY * f))
    w = np.clip((d - 1.0) / (SOFT - 1.0), 0, 1)
    w = (w * w * (3 - 2 * w))[..., None]
    out = frame.copy()
    out[:map_h] = np.clip(frame[:map_h] * (1 - w) + acc * w + 0.5, 0, 255).astype(np.uint8)
    return out


def main() -> int:
    speed = json.loads((HERE / 'speed.json').read_text(encoding='utf-8'))
    per = {f['n']: f for f in speed['frames']}
    dec = subprocess.Popen(['ffmpeg', '-v', 'error', '-i', str(SRC), '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'],
                           stdout=subprocess.PIPE)
    enc = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}',
                            '-r', '30', '-i', '-', '-i', str(SRC), '-map', '0:v', '-map', '1:a', '-c:a', 'copy',
                            '-c:v', 'libx264', '-preset', 'slow', '-crf', '16', '-pix_fmt', 'yuv420p',
                            '-color_range', 'tv', '-r', '30', '-movflags', '+faststart', str(DST)], stdin=subprocess.PIPE)
    n, touched = 0, []
    while True:
        buf = dec.stdout.read(W * H * 3)
        if len(buf) < W * H * 3:
            break
        frame = np.frombuffer(buf, np.uint8).reshape(H, W, 3)
        f = per.get(n)
        if f and strength(f['rel_speed']) > 0:
            s = strength(f['rel_speed'])
            frame = blur(frame, MAP_H[f['shot']], s)
            touched.append([n, round(s, 2)])
        enc.stdin.write(frame.tobytes())
        n += 1
    enc.stdin.close()
    ok = enc.wait() == 0 and dec.wait() == 0
    log = {'frames': n, 'blurred': touched}
    review = DST.parent / 'review_v4'
    review.mkdir(exist_ok=True)
    (review / 'speed_applied.json').write_bytes((json.dumps(log) + '\n').encode('utf-8'))
    print('wrote', DST, 'frames', n, 'blurred', touched)
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
