# Song book files (not in git)

Put song book JSON files here to bundle them with the demo build. They are
git-ignored because the lyrics may be under copyright and this repository is public.

- `songs_of_zion.json` – Songs of Zion (Telugu and English), 866 songs
- `bethel_english.json` – Bethel English Songs, 60 songs

Each file is a list of songs:

```json
[{"n": 1, "t": "English title", "tt": "Telugu title", "r": "Psalm 1", "rt": "Telugu reference",
  "te": "Telugu lyrics", "en": "English lyrics", "a": "Author (optional)"}]
```

Stanzas are separated by a blank line. The Firebase seed tool loads the same file:
`npm run seed -- --book songs-of-zion=../../assets/songs/songs_of_zion.json --book bethel-english=../../assets/songs/bethel_english.json`.

To rebuild the files from the church's Word documents, use `tools/songbooks/build_songbooks.py`
(see `docs/DEPLOY.md`, step 3).
