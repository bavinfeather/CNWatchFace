"""Check or sync the shared AOD sources for the four standalone builds."""
import argparse
from pathlib import Path


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--write', action='store_true', help='copy the canonical files to the other three projects')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
files = (
    'source/SharedAod.mc',
    'source/SharedAodFields.mc',
    'resources-aod/settings/aod-settings.xml',
    'resources/strings/aod-strings.xml',
    'resources-zhs/strings/aod-strings.xml',
)
different = []
for suffix in ('2', '3', '4'):
    project = root.with_name(root.name + suffix)
    if not (project / 'monkey.jungle').is_file():
        raise SystemExit(f'Watch face project missing: {project}')
    for name in files:
        source = (root / name).read_text(encoding='utf-8')
        target = project / name
        if target.is_file() and target.read_text(encoding='utf-8') == source:
            continue
        if args.write:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(source, encoding='utf-8')
        else:
            different.append(f'{project.name}/{name}')
if different:
    raise SystemExit('AOD files differ:\n' + '\n'.join(different))
print('Shared AOD source and settings match across all four projects.')
