# Switzer font (not in git)

The welcome screen uses **Switzer** by Indian Type Foundry. It is free for personal and
commercial use and may be embedded in the app, but its licence (ITF Free Font License) does not
allow sharing the font files in a public repository, so they are git-ignored.

Download it once before building:

```bash
curl -L -o /tmp/switzer.zip https://api.fontshare.com/v2/fonts/download/switzer
unzip -j /tmp/switzer.zip "*/WEB/fonts/Switzer-Regular.ttf" "*/WEB/fonts/Switzer-Medium.ttf" \
  "*/WEB/fonts/Switzer-Semibold.ttf" "*/License/FFL.txt" -d assets/fonts/Switzer
mv assets/fonts/Switzer/FFL.txt assets/fonts/Switzer/LICENSE.txt
```

Or download it from <https://www.fontshare.com/fonts/switzer> and copy those three files here.
