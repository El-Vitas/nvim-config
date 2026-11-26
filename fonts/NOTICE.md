# MaterialFolders font

`MaterialFolders.ttf` is a color font with the folder icons of
[Material Icon Theme](https://github.com/material-extensions/vscode-material-icon-theme) v5.36.1,
© Philipp Kief and contributors, released under the MIT License. The icons were converted to a
font so the file tree can draw them in the terminal; `lua/material_folders.lua` maps each folder
name to its glyph.

`99-material-folders.conf` is a fontconfig rule that keeps the Symbola font from claiming the same
private-use code points, which otherwise shows an empty box instead of the icon.

`install.sh` copies both into your user font folder. Without them the tree falls back to Nerd Font
folder icons.
