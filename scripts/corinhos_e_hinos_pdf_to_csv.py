import fitz, re, csv, sys, unicodedata
PDF = 'path/Corinhos e Hinos.pdf'
OUT = sys.argv[1] if len(sys.argv) > 1 else 'assets/CorinhosEHinos_Portugues.csv'
GUTTER = 310.0
SOLFEGE = {'do': 'C', 're': 'D', 'mi': 'E', 'fa': 'F', 'sol': 'G', 'la': 'A', 'si': 'B'}

def is_orange(c):
    r, g, b = (c >> 16 & 255, c >> 8 & 255, c & 255)
    return r > 200 and 60 < g < 170 and (b < 90)

def strip_accents(s):
    return ''.join((ch for ch in unicodedata.normalize('NFD', s) if unicodedata.category(ch) != 'Mn'))

def parse_key_and_title(raw):

    def tidy(s):
        return re.sub('\\s*[-–—]\\s*$', '', s).strip(' .–-')
    t = re.sub('\\s+', ' ', raw).strip()
    m = re.search('\\(([^()]+)\\)\\s*$', t)
    if not m:
        return ('', tidy(t))
    content = m.group(1).strip()
    c = strip_accents(content).lower().strip()
    key = None
    for syl, letter in SOLFEGE.items():
        if re.match(f'^{syl}\\b', c):
            key = letter + ('m' if 'menor' in c else '')
            break
    if key is None:
        mm = re.fullmatch('\\s*([a-gA-G])([#b]?)(m|menor)?\\s*', content)
        if mm:
            key = mm.group(1).upper() + mm.group(2) + ('m' if mm.group(3) else '')
    if key is None:
        return ('', tidy(t))
    return (key, tidy(t[:m.start()]))

def get_rows(page):
    spans = []
    for b in page.get_text('dict')['blocks']:
        if b.get('type') != 0:
            continue
        for ln in b['lines']:
            for s in ln['spans']:
                if s['text'].strip():
                    spans.append((s['bbox'], s['color'], s['size']))

    def lookup(x0, y0, x1, y1):
        cx, cy = ((x0 + x1) / 2, (y0 + y1) / 2)
        best, area = ((0, 11.0), 0)
        for (bx0, by0, bx1, by1), color, sz in spans:
            if bx0 <= cx <= bx1 and by0 <= cy <= by1:
                return (color, sz)
            ox = max(0, min(x1, bx1) - max(x0, bx0))
            oy = max(0, min(y1, by1) - max(y0, by0))
            if ox * oy > area:
                area, best = (ox * oy, (color, sz))
        return best
    words = []
    for x0, y0, x1, y1, w, *_ in page.get_text('words'):
        if not w.strip():
            continue
        color, sz = lookup(x0, y0, x1, y1)
        if sz >= 14:
            continue
        words.append({'x0': x0, 'x1': x1, 'yc': (y0 + y1) / 2, 'y': y0, 'text': w, 'orange': is_orange(color)})
    words.sort(key=lambda w: (round(w['yc']), w['x0']))
    rows, cur = ([], [])
    for w in words:
        if cur and abs(w['yc'] - cur[-1]['yc']) > 3:
            rows.append(cur)
            cur = []
        cur.append(w)
    if cur:
        rows.append(cur)
    pitch_src = sorted({round(min((w['y'] for w in r)), 1) for r in rows})
    diffs = [b - a for a, b in zip(pitch_src, pitch_src[1:]) if b - a > 4]
    pitch = min(diffs) if diffs else 13.4
    parts = {'L': [], 'R': []}
    for r in rows:
        for col, lo, hi in (('L', -1, GUTTER), ('R', GUTTER, 1000000000.0)):
            grp = [w for w in r if lo <= w['x0'] < hi]
            if not grp:
                continue
            txt = ' '.join((w['text'] for w in grp)).strip()
            if not txt or re.fullmatch('\\d+', txt):
                continue
            parts[col].append({'y': min((w['y'] for w in grp)), 'kind': 'title' if any((w['orange'] for w in grp)) else 'lyric', 'text': txt})
    out = []
    for col in ('L', 'R'):
        for p in sorted(parts[col], key=lambda p: p['y']):
            out.append({'col': col, 'pno': page.number, 'pitch': pitch, **p})
    return out
doc = fitz.open(PDF)
stream = []
for pno in range(doc.page_count):
    stream += get_rows(doc[pno])
songs, cur, have, last_title = ([], None, False, False)
for r in stream:
    if r['kind'] == 'title':
        if cur is not None and (not have) and last_title:
            key, t = parse_key_and_title(cur['title_raw'] + ' ' + r['text'])
            cur['title_raw'] += ' ' + r['text']
            cur['title'], cur['key'] = (t, key or cur['key'])
        else:
            key, t = parse_key_and_title(r['text'])
            cur = {'title_raw': r['text'], 'title': t, 'key': key, 'rows': []}
            songs.append(cur)
            have = False
        last_title = True
        continue
    if cur is None:
        continue
    cur['rows'].append(r)
    have = True
    last_title = False

def render(song):
    rows = song['rows']
    gaps = [b['y'] - a['y'] for a, b in zip(rows, rows[1:]) if a['col'] == b['col'] and a['pno'] == b['pno'] and (b['y'] - a['y'] > 4)]
    pitch = min(gaps) if gaps else 13.4
    out, prev = ([], None)
    for r in rows:
        if prev is not None:
            same = prev['col'] == r['col'] and prev['pno'] == r['pno']
            if not same or r['y'] - prev['y'] > 1.5 * pitch:
                out.append('')
        out.append(r['text'])
        prev = r
    res = []
    for ln in out:
        ln = ln.rstrip()
        if ln == '' and (not res or res[-1] == ''):
            continue
        res.append(ln)
    while res and res[0] == '':
        res.pop(0)
    while res and res[-1] == '':
        res.pop()
    return '\n'.join(res)
for i, s in enumerate(songs, 1):
    s['num'] = i
    s['lyrics'] = render(s)
    if not s['title']:
        first = next((ln for ln in s['lyrics'].split('\n') if ln.strip()), '')
        s['title'] = first.strip(' .,;!?')
with open(OUT, 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f, delimiter=';', lineterminator='\n', quoting=csv.QUOTE_MINIMAL)
    for s in songs:
        w.writerow([s['num'], s['title'], s['key'], s['lyrics']])
print(f'Wrote {len(songs)} songs -> {OUT}')
keys = {}
for s in songs:
    keys[s['key']] = keys.get(s['key'], 0) + 1
print('keys:', keys)
print('empty lyrics:', [s['num'] for s in songs if not s['lyrics']])
print('short(<25):', [(s['num'], s['title']) for s in songs if len(s['lyrics']) < 25])
print("titles w/ stray '(' :", [s['title'] for s in songs if '(' in s['title']][:20])
for n in (int(x) for x in sys.argv[2:] or [1, 2, 3]):
    s = next((x for x in songs if x['num'] == n), None)
    if not s:
        continue
    print('\n' + '=' * 64)
    print(f"[{s['num']}] {s['title']!r}  key={s['key']!r}")
    print('-' * 64)
    print(s['lyrics'])
