# Display modes, resolution and quality

Mirror selects the main display. Preference changes coalesce and wait for capture teardown; retired session callbacks cannot remove replacements.

Resolution choices are Native, 2K QHD (2560×1440), 4K UHD (3840×2160), 1080p and 720p, with portrait axes swapped. Native/QHD/UHD use 2× HiDPI; 720p/1080p retain 1×. A 4K desktop has a readable 1920×1080-point workspace. Large virtual modes bootstrap before promotion. Mirror preserves source aspect ratio and never upscales a lower-resolution main screen.

30/60/90/120 Hz are requested limits, still bounded by the receiver and H.264 operating envelope. Ultra detail keeps the raster and selects a 24–80 Mbps average target from the negotiated dimensions/rate; the previous quality budgets remain unchanged. It opts out of prioritizing encoder speed over quality. Average bitrate is not constant traffic or a network hard cap.

Live combined-preview tests confirmed 2560×1440 and 3840×2160 in both Mac capture and iPad receiving/format-description logs. Targets were 60 fps, 45 Mbps (2K) and 80 Mbps (4K). The WiFi 4K transition had brief stalls; sustained 4K60 and 4K120 are not claimed. A 1080p mirror remains 1080p even with a 4K preset. New controls are English/zh-Hans in FeatureStrings.xcstrings.

Settings remain global. Standalone settings navigation, language switching and cross-device settings synchronization are follow-up work.

Settings UI, language and source selection: [SETTINGS_SYNC.md](SETTINGS_SYNC.md).
