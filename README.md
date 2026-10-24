# Arachnophobia

Covers matching NPCs with opaque, filled 3D boxes fitted to their current world-space AABBs, with a small margin. Boxes draw over world geometry to keep spider models covered. NPC models remain active underneath; the plugin does not hide entities or change game menus. Name labels are clickthrough and appear above the boxes by default.

Enable or disable the plugin and name labels from its ribbon panel or Plugin Hub settings. Names containing `spider` are matched without regard to case, including familiars. Add other NPC/pet names to **Additional NPCs** as a comma-separated list of exact names.

**Cover Araxxor Fight** is **off by default**, leaving the bosses and fight-specific minions visible so their mechanics can be seen. Enable it to cover Araxxor, Araxxi, names containing `araxyte`, and Bladed, Imbued, Spitting, Mirrorback, Pulsing, Acidic, and Highly acidic spiders. This setting takes precedence over Additional NPCs. Turning it off removes boxes and labels for those NPCs on the next frame while ordinary spiders remain covered. The minion list follows the [RuneScape Wiki's Araxxor encounter reference](https://runescape.wiki/w/Araxxor).

Araxxor adds use distinct, fully opaque box colours: **Mirrorback spider — white**, **Pulsing spider — orange**, and **Acidic spider — bright red** for instant-kill danger. Other matches retain dark grey boxes. The separate Highly acidic spider retains the default colour. Labels use a dark background for readability on every box colour and draw in front of the game viewport.

Requires PrettyUI, matching the other plugins in this workspace. Load the `arachnophobia` directory as a development plugin.

**Cover Araxxor Previews** is on by default and independent of fight coverage. It covers only the Araxxi portrait area in instance creation and the Beasts details panel, plus Araxxor portrait sprites in the Beasts list. Covers are removed when changing bosses, disabling the option, or stopping the plugin. The War's Retreat portal attuned to Araxxor is covered with an opaque world box using fixed dark grey. The portal remains clickable.

Use **Box Colours** in Plugin Hub settings to choose separate colours for the default box, Araxxor, Araxxi, Mirrorback spiders, Pulsing spiders, and instant-kill Acidic spiders. Changes save automatically and apply immediately. Boxes always remain fully opaque. Additional NPCs and colour pickers are available in settings; the ribbon panel provides the quick toggles.

**Cover UI Crawlers** is on by default. It places opaque, clickthrough rectangles over `SB_OVERLAY__SMALL_SPIDER` and `SB_OVERLAY__BIG_SPIDER`, updating their position and size every frame with an eight-pixel margin for the small spider and a 32-pixel margin for the big spider to cover its legs. Covers live in `TOPLEVEL_V2__PLUGIN_BUILD_LAYER_BOTTOM`, preserving the client's ordering relative to built-in UI. Only the plugin's own child layers are raised. These use the Default Box colour and work independently of fight and preview coverage. Covers disappear when the components are hidden or unloaded, faded out, cleared, or outside their containers, when the plugin bottom layer is unavailable, when the option is disabled, or when the plugin stops. The component IDs have been confirmed in-game; the updated layer ordering still needs an in-game check.

NPC detection is name-based. Beyond the specific UI and portal covers described above, spider-shaped scenery, items, player transformations, and creatures with unrelated names are not automatically covered.

Under **Name Labels** in Plugin Hub settings, choose the background and text colours or turn off **Show Name Background** for text-only labels. These preferences save automatically, and labels remain clickthrough.

**Reset to Defaults** at the bottom of settings restores all options and colours and clears Additional NPCs. Araxxor fight coverage returns to off.
