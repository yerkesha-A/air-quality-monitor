"""Summarize real AQM FrameTiming/VM samples without publishing VM service URIs."""
import argparse
import json
import math
from pathlib import Path


def summarize(folder):
    frames = json.loads((folder / 'frame-timings.json').read_text())['frames']
    memory = json.loads((folder / 'memory-samples.json').read_text())
    after_gc = json.loads((folder / 'memory-after-gc.json').read_text())
    if not frames or not memory:
        raise ValueError('Actual samples are required; empty results are not success')

    def percentile(key, quantile):
        values = sorted(frame[key] / 1000 for frame in frames)
        return round(values[math.ceil(quantile * len(values)) - 1], 3)

    return {
        'frames': len(frames),
        'buildMedianMs': percentile('buildUs', .5),
        'buildP95Ms': percentile('buildUs', .95),
        'rasterMedianMs': percentile('rasterUs', .5),
        'rasterP95Ms': percentile('rasterUs', .95),
        'over16_67msPercent': round(100 * sum(
            max(f['buildUs'], f['rasterUs']) > 16667 for f in frames
        ) / len(frames), 2),
        'heapInitialMiB': round(memory[0]['heapUsage'] / 1048576, 2),
        'heapPeakMiB': round(max(m['heapUsage'] for m in memory) / 1048576, 2),
        'heapAfterGcMiB': round(after_gc['heapUsage'] / 1048576, 2),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('before', type=Path)
    parser.add_argument('after', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    result = {'before': summarize(args.before), 'after': summarize(args.after)}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
