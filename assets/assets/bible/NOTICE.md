# Bible texts

Both texts are bundled so the Bible works offline.

- `kjv.json.gz`: King James Version (1769 text). Public domain outside the UK.
  Source file: github.com/thiagobodruk/bible (`json/en_kjv.json`).
- `te.json.gz`: Telugu Bible, Bible Society of India old version (1880). Public domain.
  Source file: github.com/godlytalias/Bible-Database (`Telugu/bible.json`).

Format: a JSON array of 66 books; each book is an array of chapters; each chapter is an
array of verse strings. Book 0 is Genesis. Both files have identical chapter and verse counts.
