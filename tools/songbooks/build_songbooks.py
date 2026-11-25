"""Turn the church's Word song books into the app's song book files.

  python build_songbooks.py zion   --english SOZ_Master_English_1.docx --telugu SOZ_Master_Telugu_1.docx
  python build_songbooks.py bethel --docx Bethel_Songs.docx

Writes ../../assets/songs/songs_of_zion.json and ../../assets/songs/bethel_english.json
(git-ignored: the lyrics stay out of the public repository). Needs: pip install python-docx
"""
import argparse
import json
import re
from collections import Counter
from pathlib import Path

import docx  # python-docx

OUT = Path(__file__).resolve().parents[2] / 'assets' / 'songs'

# ---------------------------------------------------------------- Songs of Zion
# Titles are bold 15 pt, Bible references 10.5 pt, lyrics 12 pt.
STANZA_START = re.compile(
    r'^\s*(\d+\s*[.)]|pallavi\s*:|a\.?\s*p\.?\s*:|anupallavi\s*:|పల్లవి\s*:|అనుపల్లవి\s*:|అ\.?\s*ప\.?\s*:)', re.I)


def _kind(p):
    sizes = {r.font.size.pt for r in p.runs if r.font.size}
    if 15.0 in sizes and any(r.bold for r in p.runs):
        return 'title'
    if sizes and max(sizes) <= 11:
        return 'ref'
    return 'body'


def _parse_zion(path):
    songs, cur = [], None
    for p in docx.Document(path).paragraphs:
        text = p.text.replace(' ', ' ').rstrip()
        k = _kind(p)
        if k == 'title':
            m = re.match(r'^\s*(\d+)\s*[.)]\s*(.*)$', text)
            if m:
                cur = {'n': int(m.group(1)), 't': m.group(2).strip(), 'refs': [], 'lines': []}
                songs.append(cur)
        elif cur is None:
            continue
        elif k == 'ref':
            if text.strip():
                cur['refs'].append(text.strip())
        else:
            cur['lines'].append(text)
    for s in songs:
        stanzas, buf = [], []
        for line in s['lines']:
            if not line.strip():
                if buf:
                    stanzas.append(buf)
                    buf = []
                continue
            if STANZA_START.match(line) and buf:
                stanzas.append(buf)
                buf = []
            buf.append(line.strip())
        if buf:
            stanzas.append(buf)
        s['lyrics'] = '\n\n'.join('\n'.join(b) for b in stanzas)
        s['ref'] = re.sub(r'^[\s―—–\-,]+', '', ' '.join(s['refs'])).strip()
    return {s['n']: s for s in songs}


def zion(english, telugu):
    en, te = _parse_zion(english), _parse_zion(telugu)
    out = []
    for n in sorted(set(en) | set(te)):
        e, t = en.get(n), te.get(n)
        out.append({'n': n, 't': (e or t)['t'], 'tt': t['t'] if t else '', 'r': e['ref'] if e else '',
                    'rt': t['ref'] if t else '', 'te': t['lyrics'] if t else '', 'en': e['lyrics'] if e else ''})
    return out


# ---------------------------------------------------------------- Bethel English Songs
# Records: "Main Title: N. Title", SongNo, Version, Title, Description, Author, Song, <Start> lyrics <End>.
def _field(t, name):
    m = re.match(rf'^\s*{name}\s*:\s*(.*)$', t, re.I)
    return m.group(1).strip() if m else None


def bethel(path):
    songs, cur, mode = [], None, None
    for p in docx.Document(path).paragraphs:
        t = p.text.replace(' ', ' ').replace('\r', '\n')
        s = t.strip()
        mt = _field(s, 'Main Title')
        if mt is not None:
            m = re.match(r'^(\d+)\s*[.)]\s*(.*)$', mt)
            cur = {'n': int(m.group(1)) if m else len(songs) + 1, 't': (m.group(2) if m else mt).strip(),
                   'a': '', 'paras': []}
            songs.append(cur)
            mode = 'head'
            continue
        if cur is None:
            continue
        if mode == 'head':
            author = _field(s, 'Author')
            if author is not None:
                cur['a'] = author
            elif s.startswith('<Start>'):
                mode = 'lyrics'
                rest = s[len('<Start>'):].strip()
                if rest:
                    cur['paras'].append(rest)
            continue
        if mode == 'lyrics':
            if '<End>' in s:
                before = s.replace('<End>', '').strip()
                if before:
                    cur['paras'].append(before)
                mode = 'done'
                continue
            cur['paras'].append(t.strip('\n'))
    out = []
    for c in songs:
        stanzas = []
        for para in c['paras']:
            for block in re.split(r'\n\s*\n', para):
                lines = [line.strip() for line in block.split('\n') if line.strip()]
                if lines:
                    stanzas.append('\n'.join(lines))
        song = {'n': c['n'], 't': c['t'], 'en': '\n\n'.join(stanzas)}
        if c['a']:
            song['a'] = c['a']
        out.append(song)
    return out


def _write(name, songs):
    nums = [s['n'] for s in songs]
    dupes = [n for n, k in Counter(nums).items() if k > 1]
    missing = sorted(set(range(1, max(nums) + 1)) - set(nums))
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / name).write_text(json.dumps(songs, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    print(f'{name}: {len(songs)} songs, numbers {min(nums)}-{max(nums)}, missing {missing or "none"}, '
          f'duplicates {dupes or "none"}, without lyrics {[s["n"] for s in songs if not (s.get("en") or s.get("te"))] or "none"}')


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='book', required=True)
    z = sub.add_parser('zion')
    z.add_argument('--english', required=True)
    z.add_argument('--telugu', required=True)
    b = sub.add_parser('bethel')
    b.add_argument('--docx', required=True)
    a = ap.parse_args()
    if a.book == 'zion':
        _write('songs_of_zion.json', zion(a.english, a.telugu))
    else:
        _write('bethel_english.json', bethel(a.docx))
