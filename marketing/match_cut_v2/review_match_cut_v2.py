"""Review sheets and validation for the Change 45 moving-camera match-cut (V2): a transition sheet (the 3 frames
before and after each hard cut, full size scaled to 360x640), a phone-size sheet (the same frames at
180x320) and validation.json from ffprobe. Non-zero exit on a failed contract."""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MP4 = ROOT / 'store_assets/video/experiments/LootFarmer_MatchCut_Camera_V2.mp4'
OUT = ROOT / 'store_assets/video/experiments/review_v2'
CUTS = [60, 150, 240]  # first frame of summer, autumn, spring (output frames)


def sheet(name: str, w: int, h: int) -> None:
    sel = '+'.join(rf'between(n\,{c - 3}\,{c + 2})' for c in CUTS)
    vf = (f"select='{sel}',scale={w}:{h},pad={w + 8}:{h + 8}:4:4:white,tile=6x{len(CUTS)}")
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(MP4), '-vf', vf, '-frames:v', '1', '-vsync', '0',
                    str(OUT / name)], check=True)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    sheet('transitions_full.png', 360, 640)
    sheet('transitions_phone.png', 180, 320)
    # whole-video strip at phone size: one frame every 0.5 s
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(MP4), '-vf', 'fps=2,scale=135:240,tile=10x3',
                    '-frames:v', '1', str(OUT / 'strip_phone.png')], check=True)
    black = subprocess.run(['ffmpeg', '-i', str(MP4), '-vf', 'blackdetect=d=0.05:pix_th=0.05', '-an', '-f', 'null', '-'],
                           capture_output=True, text=True).stderr.count('black_start')
    probe = json.loads(subprocess.run(['ffprobe', '-v', 'error', '-show_streams', '-show_format', '-of', 'json', str(MP4)],
                                      capture_output=True, text=True, check=True).stdout)
    v = [s for s in probe['streams'] if s['codec_type'] == 'video']
    a = [s for s in probe['streams'] if s['codec_type'] == 'audio']
    dur = float(probe['format']['duration'])
    checks = {
        'duration_14_17': 14.0 <= dur <= 17.0,
        'one_video_h264_yuv420p': len(v) == 1 and v[0]['codec_name'] == 'h264' and v[0]['pix_fmt'] == 'yuv420p',
        'size_1080x1920': len(v) == 1 and (v[0]['width'], v[0]['height']) == (1080, 1920),
        'fps_30': len(v) == 1 and v[0]['r_frame_rate'] == '30/1',
        'one_audio_aac': len(a) == 1 and a[0]['codec_name'] == 'aac',
        'stream_count_2': len(probe['streams']) == 2,
        'no_black_frames': black == 0,
    }
    report = {'file': str(MP4.relative_to(ROOT)), 'duration': dur, 'frames': v[0].get('nb_frames') if v else None,
              'cuts_output_frames': CUTS, 'checks': checks, 'ok': all(checks.values())}
    (OUT / 'validation.json').write_bytes((json.dumps(report, indent=2) + '\n').encode('utf-8'))
    print(json.dumps(report, indent=2))
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    sys.exit(main())
