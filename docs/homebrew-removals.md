# Homebrew removals

Entries that dropped out of a per-host Brewfile when `just freeze` ran.
Compared against the previous committed Brewfile, comments ignored.

Caution: Homebrew 6.0.21 `brew bundle dump` omits formulae that come from
third-party taps. A formula such as `oven-sh/bun/bun` can vanish from the
Brewfile while it stays installed. Check with `brew list --full-name --formula`
before you treat a missing line as a removal.

## 2026-09-01

### Renames (not deletions)

- `sdl2` -> `sdl2-compat` (all three Macs)
- `nikitabobko/tap/aerospace` -> `aerospace` (Studio; cask moved to core)
- `oktadeveloper/tap` -> `oktadev/tap` (Studio, Mini)

### MacBook-Air-2025

Still installed, only missing from the dump: diffwatch, ru, apg, bun,
tandem, gogcli, poltergeist.


- brew `deemkeen/tap/diffwatch`
- brew `dicklesworthstone/tap/ru`
- brew `jzaleski/jzaleski/apg`
- brew `oven-sh/bun/bun`
- brew `rosszurowski/tap/tandem`
- brew `steipete/tap/gogcli`
- brew `steipete/tap/poltergeist`
- cask `applepi-baker`
- cask `bunch`
- cask `jordanbaird-ice@beta` (uninstalled by hand)
- cask `sublime-merge`
- cask `timemachineeditor` (uninstalled by hand)
- cask `xbar`

### Mac-Studio-2023

Still installed, only missing from the dump: jeff, espanso, apg, bun,
tandem, gogcli, stripe.


- brew `2389-research/tap/jeff`
- brew `federico-terzi/espanso/espanso`
- brew `jzaleski/jzaleski/apg`
- brew `msedit`
- brew `ollama`
- brew `oven-sh/bun/bun`
- brew `rosszurowski/tap/tandem`
- brew `steipete/tap/gogcli`
- brew `stripe/stripe-cli/stripe`
- cask `google-chrome`
- cask `jordanbaird-ice@beta`
- cask `timemachineeditor`
- cask `vibetunnel`
- tap `koekeishiya/formulae`

### Mac-Mini-Pro-2023

Still installed, only missing from the dump: espanso, apg, bun, tandem.


- brew `federico-terzi/espanso/espanso`
- brew `jzaleski/jzaleski/apg`
- brew `oven-sh/bun/bun`
- brew `rosszurowski/tap/tandem`
- cask `jordanbaird-ice` and `jordanbaird-ice@beta` (uninstalled by hand)
- cask `timemachineeditor` (uninstalled by hand)
- cask `vibetunnel` (uninstalled by hand)
- tap `koekeishiya/formulae`

### Untapped (no installed formula or cask)

- Air: `buo/cask-upgrade`
- Studio: `asmvik/formulae`, `buo/cask-upgrade`, `cmacrae/formulae`,
  `hellothisisflo/the-tap`, `hynek/tap`, `manaflow-ai/cmux`, `oktadev/tap`,
  `steipete/tap`
- Mini: `asmvik/formulae`, `buo/cask-upgrade`, `cmacrae/formulae`,
  `hynek/tap`, `oktadev/tap`, `tw93/tap`. The `yakitrak/yakitrak` tap was
  restored: obsidian-cli still comes from it.

### Bun and gogcli

- Homebrew `bun` and the `oven-sh/bun` tap removed on all three Macs. Bun now
  comes from mise only (`bun = ['latest']` in mise config).
- Old mise bun versions pruned. One version remains per Mac.
- `gogcli` and the `openclaw/tap` removed on the Air and the Studio. It was
  replaced by `gws` (googleworkspace-cli). The Mini never had it.

### Tap formulae removed

- All three Macs: `apg`, `tandem`.
- Air: `diffwatch`, `ru`, `poltergeist`, `rcli`.
- Studio: `jeff` (2389-research), `stripe`, `espanso`.
- Mini: `espanso`.
- Emptied taps untapped: jzaleski, rosszurowski, deemkeen, dicklesworthstone,
  runanywhereai, 2389-research, stripe, federico-terzi.
- Mini, later: `obsidian-cli` and the yakitrak tap. Obsidian ships its own CLI.
- Kept: `moshi-hook`, `ccmux`, `bird`, `remindctl`, `xurl`.

Caution: `brew untap` can succeed while a formula from the tap is still
installed. It did so for steipete/tap on the Air (bird) and yakitrak on the
Mini (obsidian-cli). Both taps were restored. Neither formula is in core.

### Docker

- Studio: `docker-desktop` cask and `docker-compose` formula removed.
- Mini: `docker` and `docker-compose` formulae removed.
- OrbStack ships docker, docker-compose, buildx, and kubectl on all three
  Macs, linked in `/usr/local/bin`.
