#!/usr/bin/env python3
"""Resolve the two merge-conflict hunks in main.tscn (HEAD vs user-interface-2).

Usage: python resolve_main_tscn.py path/to/main.tscn
Writes the resolved file in place and keeps a backup at main.tscn.bak.
"""
import re
import shutil
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()
shutil.copyfile(path, path + ".bak")

pat = re.compile(r"<<<<<<< [^\n]*\n(.*?)=======\n(.*?)>>>>>>> [^\n]*\n", re.S)
blocks = list(pat.finditer(text))
if len(blocks) != 2:
    sys.exit(f"Expected 2 conflict blocks, found {len(blocks)}")

OLD_ID, NEW_ID = "4_1bvp3", "4_search"   # ext_resource ID used by both sides


def split_ext(side):
    lines = side.split("\n")
    ext = [l for l in lines if l.startswith("[ext_resource")]
    rest = "\n".join(l for l in lines if not l.startswith("[ext_resource")).strip("\n")
    return ext, rest


# ---- Hunk 1: resources -------------------------------------------------
head1, ui1 = blocks[0].group(1), blocks[0].group(2)
head_ext, head_rest = split_ext(head1)
ui_ext, ui_rest = split_ext(ui1)
# only the user-interface-2 side's search_manager script gets renamed
ui_ext = [l.replace(f'id="{OLD_ID}"', f'id="{NEW_ID}"') for l in ui_ext]
merged1 = "\n".join(head_ext + ui_ext) + "\n\n" + head_rest + "\n\n" + ui_rest + "\n"

# ---- Hunk 2: nodes -----------------------------------------------------
head2, ui2 = blocks[1].group(1), blocks[1].group(2)
ui2 = ui2.replace(f'ExtResource("{OLD_ID}")', f'ExtResource("{NEW_ID}")')
ui2 = ui2.replace('parent="Ui', 'parent="Interface')   # root node is "Interface"
# HEAD's node gets its own metadata line; the shared line after the conflict
# then closes the last UI node.
merged2 = head2.rstrip("\n") + "\nmetadata/_edit_use_anchors_ = true\n\n" + ui2

out = text[:blocks[0].start()] + merged1 + text[blocks[0].end():blocks[1].start()] \
    + merged2 + text[blocks[1].end():]
open(path, "w", encoding="utf-8").write(out)

left = [m for m in ("<<<<<<<", "=======", ">>>>>>>") if re.search("^" + m, out, re.M)]
print("Resolved. Leftover markers:", left or "none")
print("Check: grep -c 'ExtResource(\"%s\")' should only match the capsule node." % OLD_ID)
