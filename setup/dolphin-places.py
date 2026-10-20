#!/usr/bin/env python3
"""Add the usual folders to Dolphin's sidebar (~/.local/share/user-places.xbel), right after Home.

Creates the file if Dolphin hasn't yet. Skips folders that are already there or don't exist.
Run it while Dolphin is closed (Dolphin rewrites the file when it quits).
"""
import os
import re
import shutil
import time
from xml.sax.saxutils import escape

HOME = os.path.expanduser("~")
PATH = os.path.join(HOME, ".local/share/user-places.xbel")

PLACES = [
    ("Desktop", "Desktop", "user-desktop"),
    ("Documents", "Documents", "folder-documents"),
    ("Downloads", "Downloads", "folder-download"),
    ("Music", "Music", "folder-music"),
    ("Pictures", "Pictures", "folder-pictures"),
    ("Videos", "Videos", "folder-videos"),
    ("Projects", "Projects", "folder-development"),
    ("GitHub", "GitHub", "folder-git"),
    ("dotfiles", "dotfiles", "folder-script"),
    (".config", "Config", "configure"),
    ("Pictures/Wallpapers", "Wallpapers", "preferences-desktop-wallpaper"),
    ("Pictures/Screenshots", "Screenshots", "camera-photo"),
]

EMPTY = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xbel>
<xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" xmlns:kdepriv="http://www.kde.org/kdepriv" xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info">
 <bookmark href="file://{escape(HOME)}">
  <title>Home</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="user-home"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="trash:/">
  <title>Trash</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="user-trash"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
</xbel>
"""


def main():
    os.makedirs(os.path.dirname(PATH), exist_ok=True)
    if os.path.exists(PATH):
        shutil.copy2(PATH, PATH + f".bak-{int(time.time())}")
        text = open(PATH, encoding="utf-8").read()
    else:
        text = EMPTY

    stamp = int(time.time())
    blocks = []
    for i, (rel, title, icon) in enumerate(PLACES):
        full = os.path.join(HOME, rel)
        href = "file://" + full
        if not os.path.isdir(full) or f'href="{href}"' in text:
            continue
        blocks.append(f""" <bookmark href="{escape(href)}">
  <title>{escape(title)}</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="{icon}"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>{stamp}/{i}</ID>
   </metadata>
  </info>
 </bookmark>
""")

    # Insert right after the Home bookmark
    home = re.search(r' <bookmark href="file://' + re.escape(HOME) + r'">.*?</bookmark>\n', text, re.S)
    pos = home.end() if home else text.rindex("</xbel>")
    text = text[:pos] + "".join(blocks) + text[pos:]
    open(PATH, "w", encoding="utf-8").write(text)
    print(f"Dolphin sidebar: added {len(blocks)} folders")


if __name__ == "__main__":
    main()
