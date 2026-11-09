#!/usr/bin/env python3
"""从 Gherkin 场景标签生成状态索引；已完成场景必须位于 finished 目录。"""
import argparse
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OPEN_STATUSES = ('partial', 'planned', 'research')
STATUSES = ('verified', *OPEN_STATUSES)


def split_scenarios(path):
    """按场景声明划分原文，保留前置注释、多行标签和原有空白。"""
    lines = path.read_text().splitlines(keepends=True)
    declarations = [index for index, line in enumerate(lines) if line.startswith('  Scenario:')]
    if not declarations:
        raise ValueError(f'{path.name}: feature has no scenario')
    starts = []
    for index in declarations:
        start = index
        while start > 0:
            previous = lines[start - 1].strip()
            if previous and not previous.startswith(('#', '@')):
                break
            start -= 1
        while start < index and not lines[start].strip():
            start += 1
        starts.append(start)
    header = ''.join(lines[:starts[0]])
    if not any(line.startswith('Feature:') for line in header.splitlines()):
        raise ValueError(f'{path.name}: missing feature header')
    ends = starts[1:] + [len(lines)]
    return header, [''.join(lines[start:end]) for start, end in zip(starts, ends)]


def scenario_status(root, path, block):
    tags, evidence = set(), []
    for line in block.splitlines():
        if line.startswith('  Scenario:'):
            break
        stripped = line.strip()
        if stripped.startswith('# evidence:'):
            evidence.append(stripped.split(':', 1)[1].strip())
        if stripped.startswith('@'):
            tags.update(re.findall(r'@([^\s]+)', stripped))
    states = tags.intersection(STATUSES)
    if len(states) != 1:
        raise ValueError(f'{path.name}: each scenario needs exactly one status: {block.splitlines()[0]}')
    state = states.pop()
    if state != 'verified':
        return state
    if not evidence:
        raise ValueError(f'{path.name}: verified scenario needs evidence')
    for reference in evidence:
        source = reference.split('::')[0].split('#')[0]
        source_path = root / source
        if not source or not source_path.is_file():
            raise ValueError(f'{path.name}: missing evidence {source}')
        if '::' in reference:
            function = reference.split('::', 1)[1]
            if f'fn {function}(' not in source_path.read_text():
                raise ValueError(f'{path.name}: missing test {function}')
    return state


def generate_index(root):
    features = root / 'features'
    files = sorted(features.rglob('*.feature'))
    if not files:
        raise ValueError('no feature files')
    open_rows, finished_rows = [], []
    totals = dict.fromkeys(STATUSES, 0)
    for path in files:
        relative = path.relative_to(features)
        if path.parent not in (features, features / 'finished'):
            raise ValueError(f'{relative}: unsupported feature directory')
        finished = path.parent.name == 'finished'
        _, blocks = split_scenarios(path)
        counts = dict.fromkeys(STATUSES, 0)
        for block in blocks:
            state = scenario_status(root, path, block)
            if (state == 'verified') != finished:
                raise ValueError(f'{relative}: {state} scenario must be ' +
                                 ('inside finished/' if state == 'verified' else 'outside finished/'))
            counts[state] += 1
            totals[state] += 1
        link = f'[{path.name}]({relative.as_posix()})'
        if finished:
            finished_rows.append(f'| {link} | {counts["verified"]} |')
        else:
            open_rows.append(f'| {link} | ' + ' | '.join(str(counts[s]) for s in OPEN_STATUSES) + ' |')

    text = '''# 功能验收索引

这些 Gherkin 文件保留完整目标，并明确当前实现边界。已完成场景放在 `finished/`，未完成场景留在本目录。它们尚未接入 Cucumber step runner；自动化证据由 Rust 和 Python 测试提供，真实链路证据在 `docs/validation.md`。不能把语法索引通过当作场景测试通过。

- `@verified`：有明确自动化测试或真实验收记录，场景内有 evidence 引用；只能出现在 `finished/`。
- `@partial`：已有代码，但仍缺全部实现或完整验收。
- `@planned`：后续实现，无当前可用承诺。
- `@research`：需要独立实验，不属于本版生产能力。
- `@p0`：当前版本闭环；`@p1`：下一版本；`@p2`：后续扩展。

下面是场景数量，不是按工作量计算的完成百分比。更新标签或移动场景后运行 `python3 scripts/feature-status.py`，再运行 `python3 scripts/feature-status.py --check`。检查器拒绝状态与目录不符的场景，并核对已完成场景的全部 evidence 引用。

| 未完成功能文件 | 部分完成 | 待实现 | 研究 |
| --- | ---: | ---: | ---: |
'''
    text += '\n'.join(open_rows) + '\n| 合计 | ' + ' | '.join(str(totals[s]) for s in OPEN_STATUSES) + ' |\n'
    text += '''
## 已完成

按场景归档；同名文件中的未完成目标仍在上表，不表示整个主题已完成。

| 功能文件 | 已完成场景 |
| --- | ---: |
'''
    text += '\n'.join(finished_rows) + f'\n| 合计 | {totals["verified"]} |\n'
    return text, totals


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    try:
        text, totals = generate_index(ROOT)
    except ValueError as error:
        raise SystemExit(str(error)) from error
    readme = ROOT / 'features/README.md'
    if args.check:
        if not readme.exists() or readme.read_text() != text:
            raise SystemExit('Feature index is stale; run python3 scripts/feature-status.py')
    else:
        readme.write_text(text)
    print('Scenarios: ' + ', '.join(f'{state}={totals[state]}' for state in STATUSES))


if __name__ == '__main__':
    main()
