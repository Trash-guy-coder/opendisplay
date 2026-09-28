# Shared settings and runtime UI language

The Mac gear button and Command-comma navigate to a settings subpage inside the existing OpenDisplay content. Back/Escape returns to the home page. There is no separate settings window. UI navigation and language changes do not recreate a capture or receiver model.

## Shared controls and ownership

Both apps use the same SwiftUI controls for display preferences, hardware-input enablement, physical Command/Option swapping, pointer speed, scroll speed, scroll reversal, performance overlay and the experimental renderer. The receiver name can also be edited from the Mac (Return commits it).

The iPad owns and persists its input/performance/name settings. The Mac displays a snapshot, sends a field patch, and the iPad applies and reports the state. Local iPad changes also report state back to the Mac. Each connected receiver has its own settings; one iPad's settings are never applied to another.

The Mac owns its existing global display mode/resolution/rate/quality/cursor preferences. iPad changes request a field patch through the same controller used by the Mac UI, retaining the coalesced stream-restart behavior. Mac changes are broadcast to connected compatible receivers.

Language is intentionally local: Follow system, Simplified Chinese, or English. Native catalogs and explicit runtime bundle selection update both literal and dynamic UI strings without an app restart. System permission dialogs, user names and raw diagnostic text are not translated protocol data.

## Wire extension

`hello` and `welcome` advertise optional `settingsVersion: 3`. Old peers ignore the additive field; controls requiring remote state remain unavailable until the capability and snapshot arrive. Video protocol 6 and minimum peer 1 are unchanged.

Messages have `{type, settingsVersion: 3, values}` envelopes:

- `receiverSettings`: complete iPad state → Mac.
- `setReceiverSettings`: changed iPad fields only, Mac → iPad.
- `senderSettings`: complete Mac display preferences → iPad.
- `setSenderSettings`: changed Mac fields only, iPad → Mac.

Requests use strict Codable types and validated allowed values/ranges. Empty, malformed, oversized (>4096 bytes), wrong-version and invalid patches are rejected. Requests apply atomically only after validation. Field patches avoid overwriting unrelated preferences; simultaneous writes to the same field resolve in delivery order. Reconnects refresh snapshots from each owning device, never blindly reapply stale defaults. These messages use the existing connected control channel; they do not introduce an independent remote-control listener.

## Validation boundaries

Independent branch build/test results are recorded in the pull request. The combined local preview was accepted by the user after real iPad/Magic Keyboard testing. The complete old/new-peer matrix, every legacy iOS device, and every simultaneous-edit/disconnect scenario are not claimed tested. Language and raw diagnostics remain separate from wire identifiers.

See [RESOLUTION_PRESETS.md](RESOLUTION_PRESETS.md) and [MIRROR_DISPLAY_SELECTION.md](MIRROR_DISPLAY_SELECTION.md).
