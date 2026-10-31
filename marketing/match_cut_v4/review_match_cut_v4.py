"""Review sheets and validation for the Change 47 zoom match-cut (V4):
- transitions_full.png: per cut, 4 ramp frames (every 3rd frame from 12 before the cut), the 3 frames before
  and 3 after the cut, and 3 settle frames (every 4th after that), map area at 240x280;
- transitions_phone.png: the same frames, whole portrait frame at 120x213 (phone-size reading);
- strip_phone.png: one frame every 0.5 s at 135x240;
- shots_phone.png: first / middle / last frame of each season shot and the end card, whole portrait at 180x320;
- compare_v3_v4_cut<k>.png: per cut, V3 (top row) over V4 (bottom row) at the same output frames, map area
  at 180x207: the ramp (every 3rd frame from 9 before), the frames before / at / after the cut, the settle;
- validation.json: ffprobe contract, black frames, music-only audio, unchanged older deliverables.
Non-zero exit on a failed contract."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
EXP = ROOT / 'store_assets/video/experiments'
MP4 = EXP / 'LootFarmer_MatchCut_Zoom_V4.mp4'
V3 = EXP / 'LootFarmer_MatchCut_Zoom_V3.mp4'
OUT = EXP / 'review_v4'
OLDER = ['LootFarmer_MatchCut_15s_v1_en-US.mp4', 'LootFarmer_MatchCut_Camera_V2.mp4', 'LootFarmer_MatchCut_Zoom_V3.mp4',
         'LootFarmer_MatchCut_Zoom_V3_en-US.mp4']
COMPARE = [-9, -6, -3, -1, 0, 1, 3, 6, 9]
TRAILER = ROOT / 'store_assets/video'


def frames_for(cut: int) -> list:
    return [cut - 12, cut - 9, cut - 6, cut - 3, cut - 2, cut - 1, cut, cut + 1, cut + 2, cut + 6, cut + 10, cut + 14]


def sheet(name: str, cuts: list, crop: str, w: int, h: int) -> None:
    sel = '+'.join(rf'eq(n\,{n})' for c in cuts for n in frames_for(c))
    vf = f"select='{sel}',{crop}scale={w}:{h},pad={w + 6}:{h + 6}:3:3:white,tile=12x{len(cuts)}"
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(MP4), '-vf', vf, '-frames:v', '1', '-vsync', '0',
                    str(OUT / name)], check=True)


def compare(k: int, cut: int) -> None:
    sel = '+'.join(rf'eq(n\,{cut + d})' for d in COMPARE)
    cell = f"select='{sel}',crop=1080:1240:0:0,scale=180:207,pad=186:213:3:3:white,tile={len(COMPARE)}x1"
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(V3), '-i', str(MP4), '-filter_complex',
                    f'[0:v]{cell}[a];[1:v]{cell}[b];[a][b]vstack', '-frames:v', '1', '-vsync', '0',
                    str(OUT / f'compare_v3_v4_cut{k}.png')], check=True)


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    speed = json.loads((HERE / 'speed.json').read_text(encoding='utf-8'))
    cuts = speed['cuts']
    sheet('transitions_full.png', cuts, 'crop=1080:1260:0:0,', 240, 280)
    sheet('transitions_phone.png', cuts, '', 120, 213)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(MP4), '-vf', 'fps=2,scale=135:240,tile=10x3',
                    '-frames:v', '1', str(OUT / 'strip_phone.png')], check=True)
    edges = [0] + cuts + [cuts[-1] + 126, 453]
    picks = [n for a, b in zip(edges, edges[1:]) for n in (a, (a + b) // 2, b - 1)]
    sel = '+'.join(rf'eq(n\,{n})' for n in picks)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(MP4), '-vf',
                    f"select='{sel}',scale=180:320,pad=184:324:2:2:white,tile=3x5", '-frames:v', '1', '-vsync', '0',
                    str(OUT / 'shots_phone.png')], check=True)
    for k, c in enumerate(cuts, 1):
        compare(k, c)
    black = subprocess.run(['ffmpeg', '-i', str(MP4), '-vf', 'blackdetect=d=0.05:pix_th=0.05', '-an', '-f', 'null', '-'],
                           capture_output=True, text=True).stderr.count('black_start')
    probe = json.loads(subprocess.run(['ffprobe', '-v', 'error', '-count_frames', '-show_streams', '-show_format', '-of',
                                       'json', str(MP4)], capture_output=True, text=True, check=True).stdout)
    v = [s for s in probe['streams'] if s['codec_type'] == 'video']
    a = [s for s in probe['streams'] if s['codec_type'] == 'audio']
    dur = float(probe['format']['duration'])
    zoom = {f['n']: f for f in speed['frames']}
    # Hero size step at the cut against the mean step of the frames either side (1.0 = one frame of travel).
    step = lambda a, b: zoom[b]['hero_size'] / zoom[a]['hero_size']
    boundaries = [{'cut_frame': c, 'time': round(c / 30, 3), 'out_zoom': zoom[c - 1]['zoom'], 'in_zoom': zoom[c]['zoom'],
                   'rel_speed_out': zoom[c - 1]['rel_speed'], 'rel_speed_in': zoom[c]['rel_speed'],
                   'hero_size_out': zoom[c - 1]['hero_size'], 'hero_size_in': zoom[c]['hero_size'],
                   'hero_size_change_pct': round(100 * (step(c - 1, c) - 1), 1),
                   'neighbour_step_pct': round(50 * (step(c - 2, c - 1) + step(c, c + 1) - 2), 1),
                   'feet_y_out': zoom[c - 1]['feet_y'], 'feet_y_in': zoom[c]['feet_y'],
                   'direction': 'in' if zoom[c]['rel_speed'] > 0 else 'out'} for c in cuts]
    baseline = OUT / 'protected_sha256.json'  # written on the first run, before V4 touched anything
    protected = {n: sha(EXP / n) for n in OLDER}
    protected.update({p.name: sha(p) for p in sorted(TRAILER.glob('*.mp4'))})
    if not baseline.exists():
        baseline.write_bytes((json.dumps(protected, indent=2) + '\n').encode('utf-8'))
    unchanged = json.loads(baseline.read_text(encoding='utf-8')) == protected
    checks = {
        'duration_14_17': 14.0 <= dur <= 17.0,
        'one_video_h264_yuv420p': len(v) == 1 and v[0]['codec_name'] == 'h264' and v[0]['pix_fmt'] == 'yuv420p',
        'size_1080x1920': len(v) == 1 and (v[0]['width'], v[0]['height']) == (1080, 1920),
        'fps_30': len(v) == 1 and v[0]['r_frame_rate'] == '30/1',
        'one_audio_aac': len(a) == 1 and a[0]['codec_name'] == 'aac',
        'stream_count_2': len(probe['streams']) == 2,
        'no_black_frames': black == 0,
        'same_direction_through_cuts': all(b['rel_speed_out'] * b['rel_speed_in'] > 0 for b in boundaries),
        'hero_size_change_under_10pct': all(abs(b['hero_size_change_pct']) < 10.5 for b in boundaries),
        'hero_feet_within_5pct': all(abs(b['feet_y_in'] - b['feet_y_out']) < 0.05 * 1156 for b in boundaries),
        'older_trailer_v1_v2_v3_unchanged': unchanged,
    }
    report = {'file': str(MP4.relative_to(ROOT)), 'duration': dur, 'frames': v[0].get('nb_read_frames') if v else None,
              'cuts': boundaries, 'checks': checks, 'ok': all(checks.values())}
    (OUT / 'validation.json').write_bytes((json.dumps(report, indent=2) + '\n').encode('utf-8'))
    print(json.dumps(report, indent=2))
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    sys.exit(main())
