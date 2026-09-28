# Display mode and stream controls

English | [简体中文](DISPLAY_SETTINGS.zh-Hans.md)

Mirror mode selects the main display. Settings changes are coalesced and wait
for old capture teardown; retired session callbacks cannot remove replacements.

Choose native, 1920x1080 or 1280x720, with orientation-aware dimensions. Native
uses HiDPI; the smaller presets use standard-pixel canvases to avoid a refused
small HiDPI mode. Requested frame-rate limits are 30/60/90/120 Hz and remain
bounded by receiver, codec and network capabilities. A target is not measured
video FPS. Mirror scaling does not change the physical main display mode.

New UI uses DisplayStrings.xcstrings with English and Simplified Chinese.
Preferences are currently global, not per-device; complete bitrate/per-device
settings from issue #9 remain follow-ups. High-rate modes need wider device
validation. Real iPad testing confirmed mirroring, stable mode switching and
the native/1080p/720p capture modes in the combined preview.
