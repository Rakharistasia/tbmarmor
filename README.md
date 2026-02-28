# tbmarmor — TBM Armor Buyer & Equipper

A MacroQuest Lua script that automates buying and equipping **The Broken Mirror (TBM)** armor, non-visible gear, and weapons from the vendor **Lyndalin Delwadamain** in the **Plane of Tranquility**.

https://tbm.eqresource.com/potranqgroupvendor.php

---

## Requirements

| Requirement | Detail |
|---|---|
| Zone | Plane of Tranquility (`potranquility`) |
| Currency | Remnants of Tranquility |
| Vendor | Lyndalin Delwadamain |
| Optional | MQ2Exchange (for cleaner item swapping) |
| Optional | MQ2Nav (for the Go to Vendor button) |

---
Run with:

```
/lua run tbmarmor
```

---

## Features

### Auto-detects your class and armor set
The script reads your class on load and selects the correct **Preserving** armor set automatically:

| Armor Set | Classes |
|---|---|
| Protector | WAR, CLR, PAL, SHD, BRD |
| Sifter | DRU, MNK, BST |
| Dredger | RNG, ROG, SHM, BER |
| Sponsor | NEC, WIZ, MAG, ENC |

### Visible armor (7-piece set)
Head, chest, arms, hands, legs, feet, and left wrist pieces are shown as checkboxes. Uncheck any slot to skip it.

### Non-visible gear — per-slot dropdowns
Each non-visible slot shows a dropdown listing every item available from the vendor for that slot. Pick exactly what you want, or set a slot to **None** to skip it entirely:

| Slot | Available items |
|---|---|
| Charm | Footman's / Inspector's / Delegator's Trinket |
| Back | Gutter-Runner's Cape / Bright Sapphire Cloak |
| Neck | Malignant Necklace / Woven Flesh Necklace |
| Face | Courtier's Mask / Rebuker's Mask / Defender's Mask (WAR/PAL/SHD/BRD) |
| Shoulder | Skirmisher's Shoulderpads / Privateering Pauldrons |
| Left Ear | Sneak's / Abettor's / Invoker's / Evoker's / Abjurer's Earring |
| Right Ear | (same pool) |
| Left Finger | Acolyte's / Delegator's / Footman's / Inspector's Ring / Ring of Depravity |
| Right Finger | (same pool) |
| Waist | Footman's Belt / Inspector's Belt |
| Ranged | Ball of Everliving Golem / Grim Idol of Dread |
| Right Wrist | Class-specific Deathscent bracer/wristguard |

> **Note:** If you select a bow in the Weapons section, the Ranged slot dropdown is automatically disabled (both compete for the same slot).

### Weapons
Checkboxes for every Armsman weapon your class can use — 1H, 2H, offhand/shield, and ranged bow.

### Reclaim Currency
The **Reclaim Currency** button opens your Inventory window, navigates to the Alternate Currency tab, and clicks **Reclaim All** to recover Remnants of Tranquility from any equipped or stored gear.

### Buy & Equip automation
1. Skips items already equipped in the correct slot
2. Opens the merchant, buys everything checked/selected that you don't already own
3. Closes the merchant
4. Equips all newly purchased items (uses MQ2Exchange if loaded, otherwise itemnotify)
5. Automatically pauses your class plugin during the process

### Other controls
- **Check Gear** — scans your current equipment against your selections and reports what's equipped, in bags, or still needs buying, without purchasing anything
- **Select All / Deselect All** — bulk toggle all slots
- **Go to Vendor** — navigates to Lyndalin Delwadamain (requires MQ2Nav); if not in the zone, attempts a travel command
- **Debug mode** — simulates the buy/equip run with console output only, no actual purchases

---

## Currency

Remnants of Tranquility are the TBM alternate currency. Your current balance is shown in the UI and updated after each purchase.

If you have gear equipped that was bought with Remnants, use **Reclaim Currency** to recover those currency points back to your character before selling or destroying the old gear.

---

## Console output

The script outputs colored status messages to the MQ2 console:

- **Green** — equipped / complete
- **Orange** — in bags, needs equipping
- **Red** — needs to be purchased
- **Teal** — currency balance
