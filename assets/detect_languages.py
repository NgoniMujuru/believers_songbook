#!/usr/bin/env python3
"""
Detect the language of each song in All.csv and write a separate CSV per language.
Output format matches input: songNumber;songTitle;songKey;songLyrics
"""
import csv
import os
import re
from collections import defaultdict

INPUT_FILE = os.path.join(os.path.dirname(__file__), 'All.csv')
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), 'languages')

# ---------------------------------------------------------------------------
# Keyword lists — primary markers carry heavy weight; secondary are common
# function words and filler words specific to the language.
# Each language needs at least one word that rarely appears in any other.
# ---------------------------------------------------------------------------
LANGUAGES = {
    'English': {
        'primary':   ['Lord', 'God', 'Saviour', 'Savior', 'salvation', 'glory',
                      'grace', 'heaven', 'praise', 'blessed', 'holy', 'Christ',
                      'blood', 'cross', 'faith', 'hope', 'love', 'eternal',
                      'Hallelujah', 'redeemed', 'King', 'throne', 'Lamb'],
        'secondary': ['the', 'and', 'that', 'have', 'for', 'not', 'with', 'from',
                      'will', 'your', 'you', 'are', 'all', 'his', 'our', 'sing',
                      'come', 'soul', 'heart', 'name', 'shall', 'who', 'when',
                      'there', 'this', 'my', 'me', 'we', 'he', 'I'],
        'pw': 8, 'sw': 1,
    },
    'French': {
        'primary':   ['Seigneur', 'Dieu', 'Sauveur', 'salut', 'gloire', 'grâce',
                      'louange', 'saint', 'Christ', 'croix', 'foi', 'amour',
                      'céleste', 'béni', 'Jésus', 'Créateur', 'éternel'],
        'secondary': ['les', 'des', 'est', 'une', 'son', 'sur', 'avec', 'pour',
                      'dans', 'nous', 'vous', 'mais', 'tout', 'pas', 'que',
                      'qui', 'mon', 'je', 'tu', 'au', 'du', 'lui', 'notre'],
        'pw': 8, 'sw': 1,
    },
    'German': {
        'primary':   ['Herr', 'Gott', 'Heiland', 'Erlösung', 'Herrlichkeit',
                      'Gnade', 'Himmel', 'heilig', 'Christus', 'Blut', 'Kreuz',
                      'Glaube', 'Liebe', 'ewig', 'gesegnet', 'Lob', 'Heil'],
        'secondary': ['der', 'die', 'das', 'und', 'ich', 'nicht', 'auch', 'wir',
                      'mir', 'dem', 'wie', 'bin', 'hat', 'mein', 'ist', 'auf',
                      'ihn', 'zu', 'ein', 'von', 'ihm', 'dir', 'dein'],
        'pw': 8, 'sw': 1,
    },
    'Português': {
        'primary':   ['Senhor', 'Deus', 'Salvador', 'salvação', 'glória', 'graça',
                      'louvor', 'santo', 'Cristo', 'sangue', 'cruz', 'fé', 'amor',
                      'eterno', 'abençoado', 'Aleluia', 'redenção'],
        'secondary': ['que', 'não', 'ele', 'uma', 'por', 'com', 'seu', 'sua',
                      'para', 'nos', 'como', 'mais', 'pelo', 'meu', 'teu',
                      'nossa', 'filho', 'ao', 'de', 'eu', 'tu', 'na', 'me'],
        'pw': 8, 'sw': 1,
    },
    'Afrikaans': {
        'primary':   ['Here', 'God', 'Heiland', 'verlossing', 'heerlikheid',
                      'genade', 'hemel', 'heilig', 'Christus', 'bloed', 'kruis',
                      'geloof', 'liefde', 'loof', 'ewig', 'geseën', 'Heer'],
        'secondary': ['die', 'van', 'het', 'wat', 'dit', 'aan', 'met', 'ons',
                      'ek', 'jy', 'sy', 'maar', 'kan', 'ook', 'nou', 'nog',
                      'sal', 'nie', 'op', 'vir', 'my', 'se', 'en', 'is'],
        'pw': 8, 'sw': 1,
    },
    'Swahili': {
        'primary':   ['Mungu', 'Bwana', 'Yesu', 'wokovu', 'utukufu', 'neema',
                      'mbingu', 'sifa', 'baraka', 'takatifu', 'Kristo', 'damu',
                      'msalaba', 'imani', 'upendo', 'milele', 'mwokozi'],
        'secondary': ['katika', 'kama', 'sisi', 'wewe', 'yeye', 'lakini', 'pia',
                      'tena', 'daima', 'naye', 'yake', 'zake', 'zetu', 'wetu',
                      'kwake', 'kwetu', 'moyo', 'roho', 'maisha', 'jina'],
        'pw': 8, 'sw': 1,
    },
    'Zulu': {
        'primary':   ['uNkulunkulu', 'Nkosi', 'uJesu', 'insindiso', 'inkazimulo',
                      'umusa', 'dumisa', 'uKristu', 'igazi', 'njalo', 'lapho',
                      'siyabonga', 'bayede', 'izulu', 'uMoya', 'ukufa'],
        'secondary': ['ngoba', 'futhi', 'naye', 'wethu', 'yethu', 'noma', 'ukuba',
                      'yena', 'nami', 'nabo', 'wami', 'kuye', 'ngaye', 'aze',
                      'simlile', 'ngize', 'ngiyo', 'lowo', 'nge'],
        'pw': 12, 'sw': 1,
    },
    'Ndebele': {
        'primary':   ['uNkulunkulu', 'iNkosi', 'uJesu', 'usindiso', 'inkazimulo',
                      'umusa', 'dumisa', 'uKristu', 'igazi', 'sibili', 'njalo',
                      'eMlanjeni', 'amangcwele', 'uMoya', 'ubomi'],
        'secondary': ['ngoba', 'futhi', 'naye', 'wethu', 'yethu', 'nxa', 'labo',
                      'kibo', 'khona', 'bona', 'mina', 'yena', 'nabo',
                      'nami', 'wami', 'kuye', 'ngaye'],
        'pw': 12, 'sw': 1,
    },
    'Shona': {
        'primary':   ['Mwari', 'Ishe', 'Jesu', 'ruponeso', 'kukudzwa', 'nyasha',
                      'denga', 'rumbidza', 'mutsvene', 'Kristu', 'ropa',
                      'rukondo', 'chitendero', 'ndinofara', 'ndinoda', 'tinoda'],
        'secondary': ['asi', 'kana', 'naye', 'zvake', 'pano', 'uyo', 'iye',
                      'tine', 'rine', 'zve', 'munhu', 'vanhu', 'pamusoro',
                      'zvinhu', 'zvino', 'chete', 'nguva'],
        'pw': 12, 'sw': 1,
    },
    'Nyanja': {
        'primary':   ['Mulungu', 'Ambuye', 'Yesu', 'chipulumutso', 'ulemerero',
                      'chisomo', 'kumwamba', 'Khristu', 'mwazi', 'chikondi',
                      'chikhulupiliro', 'Mbuye', 'yembekezera', 'mwini',
                      'Mpulumutsi', 'Yehova', 'mtendere'],
        'secondary': ['ndi', 'kuti', 'chifukwa', 'ndipo', 'timodzi', 'limodzi',
                      'koma', 'kapena', 'ngakhale', 'nthawi', 'wokhala', 'ake',
                      'tili', 'ali', 'inu', 'ife', 'iye', 'moyo', 'mtima'],
        'pw': 12, 'sw': 1,
    },
    'Tswana': {
        'primary':   ['Modimo', 'Morena', 'Jesu', 'pholoso', 'kgalalelo',
                      'bopelonomi', 'legodimo', 'Keresete', 'madi', 'bogosi',
                      'boitshepelo', 'tumelo', 'lorato', 'botshelo'],
        'secondary': ['ke', 'le', 'go', 're', 'ga', 'wa', 'ya', 'mo', 'rona',
                      'wena', 'ene', 'fa', 'fela', 'nna', 'ba', 'di',
                      'tsotlhe', 'pelo', 'mowa', 'leina'],
        'pw': 12, 'sw': 1,
    },
    'Bemba': {
        'primary':   ['Lesa', 'Mwine', 'Yesu', 'lupuliwe', 'ulukumo', 'icisomo',
                      'mumulu', 'Khristu', 'mulopa', 'ubufumu', 'ubusamfu',
                      'ukwabula', 'impendwa', 'icifulo'],
        'secondary': ['nga', 'mu', 'nge', 'ubu', 'fwe', 'lelo', 'nomba', 'pano',
                      'ico', 'buno', 'nabo', 'aba', 'ifi', 'bonse', 'nafwe',
                      'umutima', 'mweo', 'ishina', 'muulu'],
        'pw': 12, 'sw': 1,
    },
    'Lingala': {
        'primary':   ['Nzambe', 'Nkolo', 'Yesu', 'lobiko', 'nkembo', 'boboto',
                      'Klisto', 'makila', 'bomoto', 'bondeko', 'boyokani',
                      'lisalamisi', 'liloba', 'esengo'],
        'secondary': ['biso', 'oyo', 'lokola', 'lelo', 'naino', 'ndenge',
                      'ata', 'kasi', 'yango', 'mpe', 'pe', 'yo', 'na', 'ya',
                      'motema', 'molimo', 'bomoi', 'nkombo'],
        'pw': 12, 'sw': 1,
    },
    'Tagalog': {
        'primary':   ['Diyos', 'Panginoon', 'Hesus', 'kaligtasan', 'kaluwalhatian',
                      'biyaya', 'langit', 'papuri', 'banal', 'Kristo', 'dugo',
                      'krus', 'pananampalataya', 'pagmamahal', 'walang-hanggan'],
        'secondary': ['ang', 'mga', 'ay', 'ko', 'mo', 'si', 'nang', 'para',
                      'din', 'rin', 'at', 'siya', 'niya', 'namin', 'natin',
                      'ng', 'sa', 'na', 'puso', 'buhay', 'ngalan'],
        'pw': 8, 'sw': 1,
    },
    'Changana': {
        'primary':   ['Xikwembu', 'Hosi', 'Jesu', 'poniso', 'xihoniselo',
                      'nkateko', 'Kristu', 'ngati', 'vumba', 'vulavula',
                      'ntshembeko', 'xitshembiso', 'vutomi', 'vito'],
        'secondary': ['ku', 'hi', 'va', 'yi', 'ntsena', 'kambe', 'naswona',
                      'loko', 'swona', 'ra', 'le', 'ta', 'ka', 'mi', 'ya',
                      'ntima', 'moya', 'siku', 'tindlela'],
        'pw': 12, 'sw': 1,
    },
    'Kalenjin': {
        'primary':   ['Asis', 'Yesu', 'Arap', 'Cheptalel', 'Kimyet', 'korir',
                      'nebo', 'Kristu', 'mosop', 'Roho', 'sonik', 'imoch',
                      'kobore', 'muktai'],
        'secondary': ['che', 'nee', 'ko', 'ne', 'chebo', 'kole', 'eng',
                      'age', 'bik', 'mie', 'ti', 'ani', 'ago', 'miot',
                      'nebo', 'tugul', 'kimnai'],
        'pw': 12, 'sw': 1,
    },
}

# ---------------------------------------------------------------------------

def score_song(text: str, lang_data: dict) -> float:
    text_lower = text.lower()
    word_set = set(re.findall(r'\b\w+\b', text_lower))
    pw, sw = lang_data['pw'], lang_data['sw']
    score = 0.0
    for w in lang_data['primary']:
        w_l = w.lower()
        if w_l in word_set:
            # base hit + frequency bonus
            score += pw + text_lower.count(w_l) * 2
    for w in lang_data['secondary']:
        if w.lower() in word_set:
            score += sw
    return score


def detect_language(title: str, lyrics: str) -> str:
    text = lyrics + ' ' + title
    scores = {lang: score_song(text, data) for lang, data in LANGUAGES.items()}
    best = max(scores, key=scores.get)
    # Fall back to English if nothing scored at all
    return best if scores[best] > 0 else 'English'


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    buckets: dict[str, list] = defaultdict(list)
    total = 0

    with open(INPUT_FILE, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.reader(f, delimiter=';', quotechar='"')
        for row in reader:
            if len(row) < 2 or not row[0].strip():
                continue
            title  = row[1] if len(row) > 1 else ''
            lyrics = row[3] if len(row) > 3 else ''
            lang = detect_language(title, lyrics)
            buckets[lang].append(row)
            total += 1

    print(f'\n{"Language":<15} {"Songs":>6}')
    print('-' * 24)
    for lang in sorted(buckets):
        songs = buckets[lang]
        out_path = os.path.join(OUTPUT_DIR, f'{lang}.csv')
        with open(out_path, 'w', encoding='utf-8', newline='') as f:
            writer = csv.writer(f, delimiter=';', quotechar='"',
                                quoting=csv.QUOTE_MINIMAL)
            writer.writerows(songs)
        print(f'{lang:<15} {len(songs):>6}')

    print('-' * 24)
    print(f'{"Total":<15} {total:>6}')
    print(f'\nFiles written to: {OUTPUT_DIR}')


if __name__ == '__main__':
    main()
