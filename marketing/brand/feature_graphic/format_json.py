"""Rewrites composition/component JSON compactly: one layer or entry per line, so positions stay easy
to edit by hand. Usage: python marketing/brand/feature_graphic/format_json.py file.json [...]"""
import json
import sys
from pathlib import Path


def dump(value, indent=0):
    pad = '  ' * indent
    if isinstance(value, dict) and indent < 1:
        body = ',\n'.join(f'{pad}  {json.dumps(k)}: {dump(v, indent + 1)}' for k, v in value.items())
        return '{\n' + body + '\n' + pad + '}'
    if isinstance(value, list) and value and all(isinstance(v, dict) for v in value):
        body = ',\n'.join(f'{pad}  {json.dumps(v, ensure_ascii=False)}' for v in value)
        return '[\n' + body + '\n' + pad + ']'
    if isinstance(value, dict) and any(isinstance(v, dict) for v in value.values()):
        body = ',\n'.join(f'{pad}  {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}' for k, v in value.items())
        return '{\n' + body + '\n' + pad + '}'
    return json.dumps(value, ensure_ascii=False)


if __name__ == '__main__':
    for name in sys.argv[1:]:
        path = Path(name)
        path.write_text(dump(json.loads(path.read_text(encoding='utf-8'))) + '\n', encoding='utf-8', newline='\n')
