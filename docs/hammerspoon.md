# Hammerspoon

[Hammerspoon][hammerspoon] handles window management, the 2x2 display grid,
and application toggles. The configuration lives in `home/.hammerspoon/`.

| File | Purpose |
| ---- | ------- |
| `init.lua` | Loads the modules, sets the grid per screen, starts the system watchers, binds the application hotkeys |
| `config.lua` | Display names, grid sizes, and application layouts |
| `keys.lua` | Defines the `hyper` modifier |
| `sizeup.lua` | Window movement hotkeys (SizeUp emulation) |
| `display_grid.lua` | Fixes the 2x2 monitor arrangement by screen UUID |
| `logger.lua`, `tabletools.lua` | Logging and table helpers |

Press <kbd>hyper</kbd> + <kbd>r</kbd> to reload the configuration.

## Modifiers

| Name  | Key Combination                                   |
| ----- | ------------------------------------------------- |
| hyper | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>cmd</kbd> |
| meta  | <kbd>cmd</kbd> + <kbd>shift</kbd>                 |

## Window Management

| Action                    | Key Combination                                                        |
| ------------------------- | ---------------------------------------------------------------------- |
| reload config             | <kbd>hyper</kbd> + <kbd>r</kbd>                                        |
| show grid                 | <kbd>hyper</kbd> + <kbd>g</kbd>                                        |
| make full screen          | <kbd>hyper</kbd> + <kbd>m</kbd>                                        |
| center and 60%            | <kbd>hyper</kbd> + <kbd>c</kbd>                                        |
| move to left half         | <kbd>hyper</kbd> + <kbd>left</kbd>                                     |
| move to right half        | <kbd>hyper</kbd> + <kbd>right</kbd>                                    |
| move to top half          | <kbd>hyper</kbd> + <kbd>up</kbd>                                       |
| move to lower half        | <kbd>hyper</kbd> + <kbd>down</kbd>                                     |
| move to upper left (25%)  | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>shift</kbd> + <kbd>left</kbd>  |
| move to upper right (25%) | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>shift</kbd> + <kbd>up</kbd>    |
| move to lower left (25%)  | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>shift</kbd> + <kbd>down</kbd>  |
| move to lower right (25%) | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>shift</kbd> + <kbd>right</kbd> |
| move to next monitor      | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>right</kbd>                    |
| move to previous monitor  | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>left</kbd>                     |

## Display Grid (2x2 Monitor Setup)

| Action                     | Key Combination              |
| -------------------------- | ---------------------------- |
| fix 2x2 display grid       | <kbd>hyper</kbd> + <kbd>f</kbd> |
| dump display configuration | <kbd>hyper</kbd> + <kbd>9</kbd> |

## Application Toggle

| Action        | Key Combination              |
| ------------- | ---------------------------- |
| cmux          | <kbd>hyper</kbd> + <kbd>i</kbd> |
| Discord       | <kbd>hyper</kbd> + <kbd>d</kbd> |
| Slack         | <kbd>hyper</kbd> + <kbd>s</kbd> |
| Telegram      | <kbd>hyper</kbd> + <kbd>t</kbd> |
| Sublime Text  | <kbd>hyper</kbd> + <kbd>e</kbd> |
| Tower         | <kbd>hyper</kbd> + <kbd>w</kbd> |
| Zed           | <kbd>hyper</kbd> + <kbd>x</kbd> |
| Messages      | <kbd>hyper</kbd> + <kbd>a</kbd> |
| Vivaldi       | <kbd>hyper</kbd> + <kbd>v</kbd> |
| Obsidian      | <kbd>hyper</kbd> + <kbd>o</kbd> |

## Utilities

| Action                       | Key Combination              |
| ---------------------------- | ---------------------------- |
| window hints (current app)   | <kbd>hyper</kbd> + <kbd>.</kbd> |
| battery/screen callbacks     | <kbd>hyper</kbd> + <kbd>,</kbd> |
| display watcher status       | <kbd>hyper</kbd> + <kbd>0</kbd> |

[hammerspoon]: http://www.hammerspoon.org/
