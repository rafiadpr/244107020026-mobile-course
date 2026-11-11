import collections
import json
from pathlib import Path
from statistics import mean


folder = Path(__file__).resolve().parents[2] / 'docs' / 'profiling'
summary = {}
for stage in ['before', 'after']:
    frames = json.loads((folder / f'{stage}-frames.json').read_text())
    costs = [max(f['build_us'], f['raster_us']) / 1000 for f in frames]
    result = {
        'frames': len(frames),
        'mean_build_ms': mean(f['build_us'] for f in frames) / 1000,
        'mean_raster_ms': mean(f['raster_us'] for f in frames) / 1000,
        'mean_total_span_ms': mean(f['total_us'] for f in frames) / 1000,
        'max_thread_ms': max(costs),
        'yellow_60fps': sum(16.666667 < cost <= 32 for cost in costs),
        'red_60fps': sum(cost > 32 for cost in costs),
    }
    for moment in ['before', 'after']:
        memory = json.loads((folder / f'{stage}-memory-{moment}.json').read_text())
        result[f'memory_{moment}'] = memory['memoryUsage']
        result[f'instances_{moment}'] = {
            item['class']['name']: item['instancesCurrent']
            for item in memory['members']
            if item['class']['name'] in [
                '_AnnouncementListPageState', 'MaterialPageRoute',
                'AnnouncementDetailPage',
            ]
        }
    timeline = json.loads((folder / f'{stage}-timeline.json').read_text())
    stacks = collections.defaultdict(list)
    durations = collections.defaultdict(list)
    for event in sorted(timeline['traceEvents'], key=lambda e: e.get('ts', 0)):
        thread = (event.get('pid'), event.get('tid'))
        if event.get('ph') == 'B':
            stacks[thread].append(event)
        elif event.get('ph') == 'E' and stacks[thread]:
            start = stacks[thread].pop()
            durations[start['name']].append((event['ts'] - start['ts']) / 1000)
    result['timeline_max_ms'] = {
        name: max(durations[name], default=0)
        for name in ['BUILD', 'LAYOUT', 'PAINT', 'GPURasterizer::Draw']
    }
    summary[stage] = result

(folder / 'summary.json').write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
