# Mac Studio — Unexpected Reboots / "Stuck at Login" Investigation

**Machine:** Mac Studio 2023 (Mac14,13, M2 family) — `mac-studio-2023`
**macOS:** 26.4.1 (25E253)
**UPS:** CyberPower CP900AVR2 (900VA / ~540W), USB-connected, only the Studio on the battery outlet
**Investigated:** 2026-09-19
**Symptom:** Machine reboots on its own (~weekly for a month) and is found sitting at the login screen.

---

## TL;DR

- The Mac is suffering **abrupt, hard power cuts** — not software crashes, not kernel panics, not overheating, not macOS updates.
- Last event: it ran fine **all night** on 9/18, then died **instantly at 07:31:01 AM** on 9/19 and auto-restarted 53 seconds later at 07:31:54.
- It "sticks" at the login screen only because **FileVault is on + auto-login is off**, so after any unexpected restart it waits for your password. That part is expected, not a fault.
- Your UPS is healthy, correctly wired, and not overloaded — yet **macOS never logged a single switch to battery.** That means whatever cut the power did so **at or after the UPS output, invisible to the UPS.**
- **Most likely causes now (wall power is the *least* likely):**
  1. Intermittent Mac power cord / connector
  2. Failing internal power supply in the Mac Studio
  3. Intermittent UPS transfer-relay / outlet fault a self-test wouldn't catch
- **Decisive next step:** install **CyberPower PowerPanel** and see whether it logs a power event at the *next* reboot. If it does → upstream (UPS/wall). If it logs nothing → the Mac itself (cable or internal PSU → Apple service).

---

## What the logs actually showed

### 1. Reboot history — irregular, not scheduled, not updates
Recent reboots: Jul 29, Aug 11, Aug 16, Aug 21, Aug 24, Sep 9, Sep 13, Sep 19.
- Scattered across the day (06:41, 07:31, 10:10, 10:59, 14:43, 15:19, 21:05) → **not** a scheduled task.
- Auto-updates are off and `pmset -g sched` is empty → **not** update-driven.
- **None** of them have a matching clean `shutdown` record (last clean shutdown was back in April) → every one was an **unclean** power-off.

### 2. No software crash
- **Zero kernel-panic reports** in `/Library/Logs/DiagnosticReports`. A panic always writes a `.panic`/`.ips` file; there are none.
- One `JetsamEvent` (memory pressure) on 9/15 with OrbStack as the largest process, and a very high load average during investigation — worth keeping an eye on, but Jetsam kills processes, it does **not** reboot the machine. Not the reboot cause.

### 3. The 9/18→9/19 event, pinned precisely
- Kernel logged a **steady ~37–40k lines every hour** from 20:00 (9/18) through 07:00 (9/19). **No gap** → the machine was powered and running continuously all night. It did **not** go down overnight.
- The log **flatlines instantly at 07:31:01.654** on a completely normal line, with **no shutdown sequence** — no logout, no process termination, no "going to sleep," no panic, no watchdog message. It just stops mid-stream.
- Next entry is the boot at **07:31:54** (`kern.boottime` confirms). Back up in **53 seconds**.
- The 10 minutes before the cut were quiet and normal (Spotlight, a Time Machine local snapshot, background scheduler). No thermal warning, no USB disconnect, no UPS state change.
- At boot, the PMU (power management unit) fault log read `por rst uv,vdd_hi_uvlo` — `por`=power-on reset, `uv`=under-voltage, `vdd_hi_uvlo`=under-voltage lockout on the high rail. This indicates the Mac saw an under-voltage.
  - *Honesty note:* from a single boot I can't 100% prove that flag is event-specific vs. a normal latched boot artifact. But the behavioral evidence (instant flatline + no shutdown sequence + no panic + auto-restart) independently proves a hard power cut regardless of how that flag is read.

### 4. Why it's found at the login screen (expected, not a bug)
- `fdesetup status` → **FileVault is On.**
- Auto-login is **disabled.**
- `autorestart` is enabled on the AC profile → after a power cut the Mac powers itself back on, boots to the FileVault login screen, and **waits for your password** to unlock the disk. Hence "stuck at login."

### 5. UPS facts (the important twist)
- macOS sees it: `CP900AVR2 … 100%; AC attached` — so it's reading the UPS over USB.
- **Transfers to battery ever logged: `0`.** Every power-source line says "Using AC," right up to the instant death. A healthy UPS covering a mains sag would have transferred to battery and macOS would have logged it. It never did.
- **Overload ruled out:** 900VA/540W unit; Studio draws ~50–100W idle, ~300–370W peak; it's the only load on the battery outlet. Nowhere near capacity. (Also, the event happened at idle, 07:31 AM.)
- macOS's native UPS support only exposes **charge % and AC/battery state** — not watts or input voltage. To see load and input-voltage quality you need CyberPower's own software (below).

**Conclusion:** a hard power interruption reached the Mac's internals while the UPS reported clean power. That points *away* from wall/mains and *toward* the Mac's own power path or an intermittent UPS output fault.

---

## Candidate causes (most → least likely, given a vetted UPS)

1. **Mac power cord / IEC connector — intermittent.** A loose or failing cord at the Studio or at the UPS output can drop for a fraction of a second. Irregular ~weekly timing fits a mechanical intermittent. Cheapest to rule out.
2. **Mac Studio internal power supply failing.** Produces an internal under-voltage independent of clean input — fits everything: instant death, no UPS transfer, no panic, auto-restart. This is a hardware fault → Apple service.
3. **Intermittent UPS transfer-relay / battery-outlet fault.** A routine self-test is a controlled transfer and won't reproduce every real-world fast sag. You vetted it, so this is lower, but not fully excluded.
4. **Wall / mains power** — now the *least* likely, because the UPS never logged a transfer.

---

## Next steps (in priority order)

### A. Install CyberPower PowerPanel — the decisive test
Free from CyberPower's site (PowerPanel Personal for macOS). It logs every power event with **input voltage, load %, and transfer timestamps.**
At the **next** reboot:
- **PowerPanel shows a power-failure / transfer event at that instant** → the problem is upstream (UPS reacting / wall). Cross-reference against the reboot dates above.
- **PowerPanel shows nothing at the reboot instant** → UPS output was clean → the fault is the **Mac's cable or internal PSU** → move to Apple Diagnostics / service.

This single test cleanly separates "UPS/wall" from "the Mac itself," which is the fork we're stuck on.

### B. Cheap things to do right now
- **Reseat the Mac's power cord** at both ends (Studio and UPS).
- **Move the Studio to a different battery-backed outlet** on the UPS (still battery, not surge-only).
- Consider **swapping the power cord** for a known-good one.

### C. Test the Mac's own hardware
- Run **Apple Diagnostics**: shut down, then power on holding the power button until "Options," release, then press `D` (or the on-screen Diagnostics path). Look for power-related fault codes.
- If PowerPanel later shows clean power at a reboot instant, this + a Genius Bar / Apple Support visit is the path — a failing internal PSU is a repair.

### D. Optional: auto-capture the next event
I offered to add a launchd job that writes the PMU fault log + UPS state into a dated file in your dotfiles at every boot, so the next event is recorded automatically and can be correlated with PowerPanel. Say the word and I'll set it up.

### E. Side note (not the reboot cause)
Keep half an eye on the 9/15 memory-pressure JetsamEvent (OrbStack was the biggest process). It didn't cause the reboots, but if the machine ever feels sluggish, that's a separate thing to look at.

---

## Handy commands for reference

```bash
# Confirm boot time and how long up
sysctl -n kern.boottime; uptime

# Reboot / shutdown history (missing 'shutdown' lines = unclean)
last reboot | head; last shutdown | head

# Look for kernel panics (none = not a software crash)
ls -lt /Library/Logs/DiagnosticReports/ | grep -iE "panic|watchdog"

# What macOS sees of the UPS
pmset -g ps          # model, charge %, AC/battery
pmset -g ups         # macOS shutdown thresholds

# After the NEXT event: pin the death moment (adjust the time window)
log show --start "YYYY-MM-DD HH:MM:00" --end "YYYY-MM-DD HH:MM:00" \
  --predicate 'process == "kernel"' --style syslog | tail -40

# PMU fault log at boot (run soon after a reboot)
log show --start "<boot time>" --end "<boot time +2m>" \
  --predicate 'process == "kernel"' --style syslog | grep -i "pmu fault"
```

---

*Investigation notes for the Mac Studio reboot issue.*
