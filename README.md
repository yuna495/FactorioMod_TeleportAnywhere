# Teleport Anywhere

**Teleport Anywhere** is a player-only teleportation mod for Factorio 2.0.

It allows you to instantly teleport to a selected location on the current surface.

When Space Age is enabled, you can also teleport between planets that your force has already visited.

This mod teleports **only the player character**.
Items, vehicles, trains, cargo, and other entities cannot be transported by teleportation.

This means you can reduce the time spent traveling across large factories or between planets without replacing Factorio's normal logistics systems.

---

## Features

### Map Teleport

Teleport to a selected location on your current surface.

1. Click the Teleport Anywhere icon in the upper-left corner of the screen.
2. Select `Map Teleport`.
3. Open Remote View and select the area you want to teleport to.
4. You will be teleported near the center of the selected area.

If the destination is obstructed by buildings, water, cliffs, or other obstacles, the mod uses Factorio's collision system to automatically search for a nearby valid position.

If no safe position can be found, the teleport is cancelled.

---

## Space Age Support

Space Age is an **optional dependency**.

### Factorio 2.0 without Space Age

The following features are available:

* Map Teleport within the current surface
* Destination selection through Remote View
* Automatic safe-position search

### Factorio 2.0 + Space Age

In addition to the features above, you can use:

* Teleportation between previously visited planets
* Support for planets added by other mods

---

## Planet Teleport

When Space Age is enabled, planets your force has already visited are displayed in the Teleport Anywhere GUI.

Example:

```text
Teleport Anywhere

Current: Nauvis

[ Map Teleport ]

Planets

[ Nauvis - Current ]
[ Vulcanus ]
[ Fulgora ]
```

Select a destination planet to teleport directly to it.

### Visited Planets Only

You cannot teleport to a planet that your force has never visited.

For your first trip to Vulcanus, Fulgora, or another planet, you must travel there normally using a Space Platform.

Once your force has physically reached a planet, that planet becomes available through Teleport Anywhere.

This prevents the mod from bypassing the initial planetary progression of Space Age.

---

## Planet Arrival Location

When teleporting between planets, the destination is selected in the following order:

1. Near the **Cargo Landing Pad**
2. If no Cargo Landing Pad exists, near the planet's **spawn position**

The player is not placed directly at the reference position. The mod searches the surrounding area for a valid position where the player character can safely be placed.

---

## Modded Planet Support

Planet names are not hardcoded.

In Space Age, Teleport Anywhere retrieves available planets from Factorio's Planet data, allowing it to automatically support planets added by other mods whenever possible.

Special-purpose surfaces and surfaces that are not registered as normal planets are not supported.

---

## Space Platforms

Teleportation to or from Space Platforms is not supported.

The following are not available:

* Planet → Space Platform
* Space Platform → Planet
* Space Platform → Space Platform
* Map Teleport within a Space Platform

Use the normal Space Age systems for Space Platform travel.

---

## Controls

### GUI

A Teleport Anywhere icon is displayed in the upper-left corner of the game screen.

Click it to open or close the Teleport GUI.

### Keyboard Shortcut

Default:

```text
Alt + M
```

Opens or closes the Teleport GUI.

The key binding can be changed in Factorio's control settings.

---

## Selecting a Map Teleport Destination

Map Teleport uses Factorio's standard Selection Tool.

After clicking `Map Teleport`, select an area around your desired destination.

The **center of the selected area** is used as the target position.

For precise positioning, select a small area around the desired tile.

---

## Safe Position Search

Teleport Anywhere does not use hardcoded checks for individual obstacles such as water or buildings.

Instead, it uses Factorio's collision system to determine whether the player character can be safely placed at the destination.

If the selected position is blocked, the mod searches the surrounding area for a valid position.

If no safe position can be found, the teleport is cancelled rather than forcing the player into an invalid location.

---

## What Gets Teleported

Teleported with the player:

* Player character
* Items normally carried in the player's inventory
* Equipped armor and equipment

Not teleported:

* Vehicles
* Spidertrons
* Trains
* Buildings
* Robots
* Logistics cargo
* Other units

Teleportation is not available while the player is inside a vehicle.

---

## Multiplayer

Multiplayer is supported.

GUI state and Map Teleport selection state are managed separately for each player.

In Space Age, visited planets are tracked per force.

This means that players belonging to the same force can teleport to planets that have already been visited by that force.

---

## Design Philosophy

Teleport Anywhere is not intended to replace Factorio's logistics systems with teleportation.

Its purpose is:

> **To remove the travel time required only to move the player between places they can already reach.**

Moving resources between factories still requires belts, trains, logistic robots, or other normal logistics systems.

Likewise, transporting resources between planets in Space Age still requires rockets, Space Platforms, Cargo Landing Pads, and the normal interplanetary logistics system.

Teleport Anywhere is intended for situations such as:

* Quickly checking a distant part of your factory
* Making a small adjustment to your factory on Vulcanus
* Returning to Nauvis after checking something on Fulgora

In other words, the mod reduces **player travel time** without replacing the logistics gameplay itself.

---

## Requirements

* Factorio 2.0
* Space Age (optional)

Map Teleport is fully available without Space Age.

---

## Version 1.0

Features:

* Map Teleport
* Destination selection using a Selection Tool
* Remote View support
* Safe-position search
* GUI
* Keyboard shortcut
* Optional Space Age support
* Teleportation between visited planets
* Cargo Landing Pad arrival
* Spawn-position fallback
* Dynamic support for modded planets
* Multiplayer support
* English and Japanese localization

---

## License

MIT
