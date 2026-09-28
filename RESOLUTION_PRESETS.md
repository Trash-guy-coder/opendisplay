# iPad native presets and custom pixels

The automatic Native label includes the connected receiver's actual reported pixel dimensions. With multiple receivers, each iPad receives its own native-dimension metadata; the Mac uses an automatic label when no single device represents all sessions.

Model presets name a specific generation instead of assuming every member of a family has the same display. Dimensions below are landscape physical pixels; portrait orientation swaps axes.

| Preset | Pixels | Official specification |
| --- | --- | --- |
| iPad 10.2-inch (9th generation) | 2160×1620 | https://support.apple.com/en-sg/111898 |
| iPad (A16) | 2360×1640 | https://support.apple.com/en-gb/122240 |
| iPad Air 11-inch (M3) | 2360×1640 | https://support.apple.com/en-gb/122241 |
| iPad Air 13-inch (M3) | 2732×2048 | https://support.apple.com/en-za/122242 |
| iPad Pro 11-inch (4th generation) | 2388×1668 | https://support.apple.com/en-sg/111842 |
| iPad Pro 11-inch (M4) | 2420×1668 | https://support.apple.com/en-au/119892 |
| iPad Pro 12.9-inch (6th generation) | 2732×2048 | https://support.apple.com/en-ie/111841 |
| iPad Pro 13-inch (M4) | 2752×2064 | https://support.apple.com/en-au/119891 |

Choosing Custom opens local draft fields. No stream restart occurs until Apply. Each side accepts 320–8192 pixels in multiples of four, preserving exact pixels with the existing even-point 2× HiDPI canvas. Width/height travel as one validated patch; incomplete pairs are rejected. The saved custom dimensions persist, and orientation follows the receiver. The editor can fill the current receiver's native size.

Preset names describe desktop pixel sizes, not hardware identity or a promise of a given frame rate. Mirror retains the selected existing display's source pixels and aspect ratio without upscaling; use Extend to create a desktop at a selected iPad/native/custom raster. Codec and receiver envelopes can still downscale the transmitted stream or lower its rate; the negotiated configuration remains visible.

Optional settings capability is now `settingsVersion: 3` to distinguish custom pixel pairs and the expanded resolution enum. Both apps must be updated for settings synchronization. The H.264/input wire protocol and minimum peer remain unchanged. Native dimensions are read-only metadata and cannot change a receiver's advertised hardware dimensions through a settings request.

Validation: preset geometry, custom input validation and capability-limited encoding are covered by tests. The combined preview captured and received native/2K/4K rasters. Target FPS is not sustained throughput; custom-resolution end-to-end acceptance is not claimed for every size.

## 简体中文

“原生”现在会显示已连接设备的真实像素。本机已识别为 2388×1668。上表列出普通 iPad、iPad Air、11 英寸和 12.9 英寸 iPad Pro 等常见原生预设，按具体代际标注。

选择“自定义分辨率”后输入宽高，再点击“应用自定义分辨率”才生效。每边支持 320–8192 像素，需为 4 的倍数；可一键填入设备原生尺寸，横竖方向跟随接收设备。Mac 和 iPad 共用这些选项并同步设置。

镜像像素由“镜像显示屏”中选定的屏幕决定；要按 iPad 原生或自定义尺寸创建桌面，请选择扩展模式。实际协商尺寸和帧率可能受设备、编码能力限制。

预设与自定义尺寸有自动测试覆盖；完整设备矩阵和所有自定义尺寸的实际表现仍需更多验证。
