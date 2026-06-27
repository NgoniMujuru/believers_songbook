import fitz, re, csv, sys
from statistics import median
PDF = '/path/Cifrario TraduzInos 2020 para impressao.pdf'
OUT = sys.argv[1] if len(sys.argv) > 1 else 'assets/CifrarioTraduzInos_Portugues.csv'
NUM_TITLE = re.compile('^\\s*\\d{1,2}\\s*[–\\-]')
GX = 298.0
TITLE_SZ = 12.0

def colour_kind(color):
    r, g, b = (color >> 16 & 255, color >> 8 & 255, color & 255)
    if r > 150 and g < 110 and (b < 110):
        return 'chord'
    if b > 120 and r < 110:
        return 'link'
    if r > 28 and abs(r - g) < 18 and (abs(g - b) < 18) and (r < 90):
        return 'subtitle'
    return 'lyric'

def get_rows(page):
    spans = []
    for b in page.get_text('dict')['blocks']:
        if b.get('type') != 0:
            continue
        for ln in b['lines']:
            for s in ln['spans']:
                if s['text'].strip():
                    bold = s['font'].endswith('Bold') or bool(s['flags'] & 16)
                    spans.append((s['bbox'], s['color'], bold, s['size']))

    def lookup(x0, y0, x1, y1):
        cx, cy = ((x0 + x1) / 2, (y0 + y1) / 2)
        best, area = ((0, False, 10.0), 0)
        for (bx0, by0, bx1, by1), color, bold, sz in spans:
            if bx0 <= cx <= bx1 and by0 <= cy <= by1:
                return (color, bold, sz)
            ox = max(0, min(x1, bx1) - max(x0, bx0))
            oy = max(0, min(y1, by1) - max(y0, by0))
            if ox * oy > area:
                area, best = (ox * oy, (color, bold, sz))
        return best
    words = []
    for x0, y0, x1, y1, w, *_ in page.get_text('words'):
        if not w.strip():
            continue
        color, bold, sz = lookup(x0, y0, x1, y1)
        ck = colour_kind(color)
        if ck in ('link', 'subtitle'):
            continue
        words.append({'x0': x0, 'x1': x1, 'yc': (y0 + y1) / 2, 'y': y0, 'text': w, 'ck': ck, 'bold': bold, 'sz': sz})
    words.sort(key=lambda w: (round(w['yc']), w['x0']))
    rows, cur = ([], [])
    for w in words:
        if cur and abs(w['yc'] - cur[-1]['yc']) > 3:
            rows.append(cur)
            cur = []
        cur.append(w)
    if cur:
        rows.append(cur)
    out = []
    for ws in rows:
        ws.sort(key=lambda w: w['x0'])
        out.append({'y': min((w['y'] for w in ws)), 'words': ws})
    out.sort(key=lambda r: r['y'])
    return out

def part_kind(ws):
    text = ' '.join((w['text'] for w in ws))
    bold = any((w['bold'] for w in ws))
    big = max((w['sz'] for w in ws)) >= TITLE_SZ
    if bold and big:
        return 'title' if NUM_TITLE.match(text) else 'header'
    if sum((w['ck'] == 'chord' for w in ws)) > len(ws) / 2:
        return 'chord'
    return 'lyric'

def has_title(ws):
    return part_kind(ws) == 'title'

def clean_title(raw):
    t = re.sub('^\\s*\\d{1,2}\\s*[–\\-]\\s*', '', raw.strip())
    t = re.sub('^(Hinos?\\s*/?\\s*)?Corinhos?\\s*:\\s*', '', t, flags=re.I)
    t = re.split('\\s*/\\s*\\d', t)[0]
    t = re.split('\\s+/\\s+', t)[0]
    t = re.split('\\s+[–\\-]\\s+\\d', t)[0]
    t = re.split('\\s+[–\\-]\\s+Original', t, flags=re.I)[0]
    t = re.sub('\\s+', ' ', t)
    t = re.sub('\\s*[-–—]\\s*$', '', t)
    t = re.sub('\\s+[A-G][#b]?(?:m|7|maj|sus)?\\d?$', '', t)
    return t.strip(' .')

def clean_key(text):
    m = re.match('^([A-G][#b]?m?)', text.strip())
    return m.group(1) if m else ''

def resolve_page(rows, pno, pitch):
    big = 2.8 * pitch
    for r in rows:
        r['wide'] = any((w['x0'] < GX < w['x1'] for w in r['words']))
        r['L'] = [w for w in r['words'] if w['x0'] < GX]
        r['R'] = [w for w in r['words'] if w['x0'] >= GX]
    segments, buf, prev = ([], [], None)

    def flush():
        nonlocal buf
        if buf:
            two = any((r['R'] for r in buf)) and any((r['L'] for r in buf))
            segments.append(('double' if two else 'single', buf))
            buf = []
    for r in rows:
        is_big = prev and r['y'] - prev['y'] > big and (part_kind(prev['words']) not in ('title', 'header'))
        if r['wide']:
            if r['L'] and r['R'] and has_title(r['R']):
                flush()
                segments.append(('double', [r]))
            else:
                flush()
                segments.append(('single', [r]))
            prev = r
            continue
        if is_big:
            flush()
        buf.append(r)
        prev = r
    flush()
    stream = []
    state = {'blk': 0, 'last_y': None, 'mode': None}

    def emit(r, ws, two):
        k = part_kind(ws)
        if k in ('title', 'header'):
            ws = [w for w in ws if w['ck'] != 'chord'] or ws
        stream.append({'pno': pno, 'blk': state['blk'], 'two': two, 'y': r['y'], 'kind': k, 'text': ' '.join((w['text'] for w in ws)).strip()})
    for kind, seg in segments:
        if kind == 'double':
            for side in ('L', 'R'):
                grp = [r for r in seg if r[side]]
                if not grp:
                    continue
                state['blk'] += 1
                for r in grp:
                    emit(r, r[side], True)
            state['mode'], state['last_y'] = ('double', None)
        else:
            for r in seg:
                k = part_kind(r['words'])
                if state['mode'] != 'single' or state['last_y'] is None or k == 'title' or (r['y'] - state['last_y'] > big):
                    state['blk'] += 1
                emit(r, r['words'], False)
                state['mode'], state['last_y'] = ('single', r['y'])
    return stream
doc = fitz.open(PDF)
PITCH = {}
stream = []
for pno in range(1, doc.page_count):
    rows = get_rows(doc[pno])
    ys = sorted({round(r['y'], 1) for r in rows})
    diffs = [b - a for a, b in zip(ys, ys[1:]) if b - a > 4]
    PITCH[pno] = min(diffs) if diffs else 13.0
    stream += resolve_page(rows, pno, PITCH[pno])
songs, cur, have = ([], None, False)
for row in stream:
    k = row['kind']
    if k == 'title':
        num = int(re.match('^\\s*(\\d{1,2})', row['text']).group(1))
        cur = {'num': num, 'title': clean_title(row['text']), 'key': '', 'rows': []}
        songs.append(cur)
        have = False
        continue
    if cur is None:
        continue
    if k == 'header':
        if have:
            cur['rows'].append(dict(row, text=clean_title(row['text'])))
        continue
    cur['rows'].append(row)
    if k == 'lyric':
        have = True
    elif k == 'chord' and (not cur['key']):
        cur['key'] = clean_key(row['text'])

def render_block(rows, two, pitch):
    rows = sorted(rows, key=lambda r: r['y'])
    if two:
        out = []
        for r in rows:
            if r['kind'] == 'header':
                out += ['', r['text']]
            elif r['kind'] == 'lyric':
                out.append(r['text'])
        return out
    origin = rows[0]['y']
    slots = {}
    for r in rows:
        s = round((r['y'] - origin) / pitch)
        if r['kind'] in ('lyric', 'header'):
            slots[s] = (r['kind'], r['text'])
        else:
            slots.setdefault(s, ('chord', ''))
    out = []
    for s in range(max(slots) + 1):
        cell = slots.get(s)
        if cell is None:
            out.append('')
        elif cell[0] == 'header':
            out += ['', cell[1]]
        elif cell[0] == 'lyric':
            out.append(cell[1])
    return out

def render_song(song):
    blocks, order = ({}, [])
    for r in song['rows']:
        key = (r['pno'], r['blk'])
        if key not in blocks:
            blocks[key] = []
            order.append(key)
        blocks[key].append(r)
    out = []
    for key in order:
        rs = blocks[key]
        block = render_block(rs, rs[0]['two'], PITCH[key[0]])
        if any((ln.strip() for ln in block)):
            if out and out[-1] != '':
                out.append('')
            out += block
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
for s in songs:
    s['lyrics'] = render_song(s)
with open(OUT, 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f, delimiter=';', lineterminator='\n', quoting=csv.QUOTE_MINIMAL)
    for s in songs:
        w.writerow([s['num'], s['title'], s['key'], s['lyrics']])
print(f'Wrote {len(songs)} songs -> {OUT}')
nums = [s['num'] for s in songs]
print('Nums:', nums, 'count', len(nums))
print('Missing 1..57:', [n for n in range(1, 58) if n not in nums])
print('Duplicates:', sorted({n for n in nums if nums.count(n) > 1}))
flags = [s['num'] for s in songs if len(s['lyrics']) < 40 or not s['lyrics']]
print('Suspiciously short:', flags)
for n in (int(x) for x in sys.argv[2:] or [1, 2, 3, 6, 9, 11, 21, 22]):
    s = next((x for x in songs if x['num'] == n), None)
    if not s:
        print(f'\n[{n}] MISSING')
        continue
    print('\n' + '=' * 70)
    print(f"[{s['num']}] title={s['title']!r}  key={s['key']!r}")
    print('-' * 70)
    print(s['lyrics'])
