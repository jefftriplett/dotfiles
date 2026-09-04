# Stream Deck

An Elgato Stream Deck provides hardware buttons for lights, media, and
shortcuts. Two devices are connected:

| Device | Model | Buttons | Role |
| ------ | ----- | ------- | ---- |
| Stream Deck (15-key) | 20GAA9902 | 5 × 3 grid | Main control surface |
| Stream Deck (3-key) | 20GBF9901 | 3 × 1 strip | Desk lights, mute toggle, media |

## Profiles

The 15-key deck switches between profiles with a dedicated button:

| Profile | Purpose |
| ------- | ------- |
| **Meetings** | Lights (Elgato Key Light, Philips Hue), mute toggle, media controls, sleep |
| **AV Setup** | Light temperature and brightness, media, CPU monitor |
| **Profile 1** | Hotkeys for window management |

The 3-key deck uses a single **Default Profile** with desk lights, mute
toggle, and media.

## Editing profiles

The Elgato Stream Deck app owns the config files under
`~/Library/Application Support/com.elgato.StreamDeck/ProfilesV3/`. Each
`.sdProfile` directory contains a `manifest.json` and per-page manifests
under `Profiles/`.

The app writes its in-memory state back to disk, so edits made while it
is running are silently reverted. To edit the JSON directly:

```shell
osascript -e 'quit app "Elgato Stream Deck"'
# ... edit the manifest.json ...
open -a "Elgato Stream Deck"
```

## Button grid coordinates

Keys in the manifest use `"col,row"` coordinates (zero-indexed,
origin at top-left):

```
0,0  1,0  2,0  3,0  4,0    ← top row
0,1  1,1  2,1  3,1  4,1    ← middle row
0,2  1,2  2,2  3,2  4,2    ← bottom row
```

## Common action UUIDs

| Action | UUID | Settings |
| ------ | ---- | -------- |
| Key Light on/off | `com.elgato.controlcenter.lights-on-off` | `deviceID`, `name` |
| Philips Hue on/off | `com.elgato.philips-hue.power` | `bridge`, `light` |
| Philips Hue scene | `com.elgato.philips-hue.scene` | `bridge`, `light`, `scene` |
| Philips Hue color | `com.elgato.philips-hue.color` | `bridge`, `light`, `color` |
| Multimedia | `com.elgato.streamdeck.system.multimedia` | `actionIdx` (0=mute, 1=play/pause, 3=prev, 4=next, 5=vol up, 6=vol down) |
| Hotkey | `com.elgato.streamdeck.system.hotkey` | `Hotkeys[]` with key codes |
| Website | `com.elgato.streamdeck.system.website` | `openInBrowser`, `path` |
| Switch Profile | `com.elgato.streamdeck.profile.rotate` | `ProfileUUID` |
| Sleep | `com.elgato.streamdeck.system.sleep` | `DeviceUUID` |
