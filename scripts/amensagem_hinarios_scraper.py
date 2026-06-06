import os, re, csv, sys, time, html as ihtml, urllib.request
from bs4 import BeautifulSoup
HINARIOS = 'https://amensagem.org/biblioteca/hinarios/'
CACHE = '/tmp/amensagem_cache'
UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) songbook-import/1.0'
os.makedirs(CACHE, exist_ok=True)

def fetch(url, delay=0.4):
    key = re.sub('[^a-zA-Z0-9]+', '_', url).strip('_')[:120] + '.html'
    path = os.path.join(CACHE, key)
    if os.path.exists(path):
        return open(path, encoding='utf-8', errors='replace').read()
    last = None
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA})
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read().decode('utf-8', 'replace')
            open(path, 'w', encoding='utf-8').write(data)
            time.sleep(delay)
            return data
        except Exception as e:
            last = e
            time.sleep(1.5 * (attempt + 1))
    raise last

def clean_line(s):
    s = s.replace('\xa0', ' ').replace('\u200b', '')
    s = ihtml.unescape(s)
    return re.sub('[ \\t]+', ' ', s).strip()

def _keep(line):
    if not line:
        return False
    if re.match('^https?://\\S+$', line):
        return False
    if re.match('^CL\\s*\\d+\\s*[–\\-]', line, re.I):
        return False
    if re.match('^(Autor|Tradutor|Letra|M[úu]sica|Compositor)\\b', line, re.I):
        return False
    if line.startswith('***'):
        return False
    return True

def parse_lyrics(page_html, name=''):
    soup = BeautifulSoup(page_html, 'lxml')
    ec = soup.select_one('div.entry-content')
    if not ec:
        return ''
    for bad in ec.select('script,style,figure,.sharedaddy,.jp-relatedposts,.crp_related,.addtoany_share_save_container,.sd-sharing'):
        bad.decompose()
    stanzas = []
    ps = ec.find_all('p')
    if ps:
        for p in ps:
            for br in p.find_all('br'):
                br.replace_with('\n')
            lines = [x for x in (clean_line(l) for l in p.get_text().split('\n')) if _keep(x)]
            if lines:
                stanzas.append('\n'.join(lines))
    if not stanzas:
        for h in ec.find_all(['h1', 'h2', 'h3']):
            h.decompose()
        for br in ec.find_all('br'):
            br.replace_with('\n')
        block = []
        for ln in ec.get_text('\n').split('\n'):
            ln = clean_line(ln)
            if _keep(ln):
                block.append(ln)
            elif block:
                stanzas.append('\n'.join(block))
                block = []
        if block:
            stanzas.append('\n'.join(block))
    norm = lambda s: re.sub('[^a-z0-9]', '', s.lower())
    if name and len(stanzas) > 1 and ('\n' not in stanzas[0]) and (norm(stanzas[0]) == norm(name)):
        stanzas = stanzas[1:]
    return '\n\n'.join(stanzas).strip()

def get_song_list(tid='30'):
    soup = BeautifulSoup(fetch(HINARIOS), 'lxml')
    out = []
    for tr in soup.find('table', id=f'tablepress-{tid}').find('tbody').find_all('tr'):
        tds = tr.find_all('td')
        if len(tds) < 2:
            continue
        a = tds[1].find('a')
        if not a:
            continue
        out.append((clean_line(tds[0].get_text()), clean_line(tds[1].get_text()), a['href'].replace('http://', 'https://')))
    return out
if __name__ == '__main__':
    mode = sys.argv[1] if len(sys.argv) > 1 else 'test'
    songs = get_song_list()
    print(f'tab1 songs: {len(songs)}', file=sys.stderr)
    if mode == 'test':
        for num, name, url in [songs[0], songs[1], songs[4], songs[99]]:
            print('\n' + '=' * 66)
            print(f'[{num}] {name}  <- {url}')
            print('-' * 66)
            print(parse_lyrics(fetch(url), name))
    else:
        out = sys.argv[2]
        tid = sys.argv[3] if len(sys.argv) > 3 else '30'
        songs = get_song_list(tid)
        print(f'tab {tid} songs: {len(songs)}', file=sys.stderr)
        rows = []
        for i, (num, name, url) in enumerate(songs, 1):
            lyr = parse_lyrics(fetch(url), name)
            rows.append([num, name, '', lyr])
            if i % 50 == 0:
                print(f'  {i}/{len(songs)}', file=sys.stderr)
        with open(out, 'w', newline='', encoding='utf-8') as f:
            w = csv.writer(f, delimiter=';', lineterminator='\n', quoting=csv.QUOTE_MINIMAL)
            w.writerows(rows)
        empty = [r[0] for r in rows if not r[3].strip()]
        print(f'wrote {len(rows)} -> {out}; empty lyrics: {empty}', file=sys.stderr)
