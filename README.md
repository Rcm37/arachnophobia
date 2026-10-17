# Arachnophobia

Covers matching NPCs with opaque, filled 3D boxes fitted to their current world-space AABBs, with a small margin. Boxes draw over world geometry to keep spider models covered. NPC models remain active underneath; the plugin does not hide entities or change game menus. Name labels are clickthrough and appear above the boxes by default.

Enable or disable the plugin and name labels from its ribbon panel or Plugin Hub settings. Names containing `spider` are matched without regard to case, including familiars. Add other NPC/pet names to **Additional NPCs** as a comma-separated list of exact names.

**Cover Araxxor Fight** is **off by default**, leaving the bosses and fight-specific minions visible so their mechanics can be seen. Enable it to cover Araxxor, Araxxi, names containing `araxyte`, and Bladed, Imbued, Spitting, Mirrorback, Pulsing, Acidic, and Highly acidic spiders. This setting takes precedence over Additional NPCs. Turning it off removes boxes and labels for those NPCs on the next frame while ordinary spiders remain covered. The minion list follows the [RuneScape Wiki's Araxxor encounter reference](https://runescape.wiki/w/Araxxor).

Araxxor adds use distinct, fully opaque box colours: **Mirrorback spider — white**, **Pulsing spider — orange**, and **Acidic spider — bright red** for instant-kill danger. Other matches retain dark grey boxes. The separate Highly acidic spider retains the default colour. Labels use a dark background for readability on every box colour and draw in front of the game viewport.

Requires PrettyUI, matching the other plugins in this workspace. Load the `arachnophobia` directory as a development plugin.

Detection is name-based and only covers NPCs. Spider-shaped scenery, items, player transformations, and creatures with unrelated names are not automatically covered.
