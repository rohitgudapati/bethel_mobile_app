# Song book files (not in git)

Put song book JSON files here to bundle them with the demo build. They are
git-ignored because the lyrics may be under copyright and this repository is public.

`songs_of_zion.json` – a list of songs:

```json
[{"n": 1, "t": "English title", "tt": "Telugu title", "r": "Psalm 1", "rt": "Telugu reference",
  "te": "Telugu lyrics", "en": "English lyrics"}]
```

Stanzas are separated by a blank line. The Firebase seed tool loads the same file:
`npm run seed -- --songs ../../assets/songs/songs_of_zion.json`.
