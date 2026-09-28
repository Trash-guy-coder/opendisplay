# Select an existing mirror display

Mirror and Extend remain separate modes. In **Mirror**, a new **Mirror display** picker lists existing Mac screens by name and logical dimensions, including externally managed HiDPI virtual displays. Selecting a screen captures that screen; it never creates, resizes, or changes the primary display.

The selection persists by CoreGraphics display UUID, so changing numeric display IDs does not change the selected screen. Initial capture and capture reconfiguration both resolve that UUID. If the selected display disappears, the app reports it unavailable rather than silently capturing the physical main screen. The screen inventory refreshes on macOS display-change notifications. Session-owned OpenDisplay extensions are excluded because they disappear when leaving Extend.

Both devices show the same picker via settings capability version 3. Screen names, point dimensions and pixel dimensions are read-only metadata; remote edits can only select a display in the Mac's current allowed inventory. The Native resolution label follows the chosen source pixels. A 1194×834-point HiDPI source is captured at 2388×1668 pixels. Legacy touch input is also bound to the selected capture display.

## Verification boundaries

Tests cover explicit physical/virtual selection, unavailable-display handling without fallback, stable UUID lookup and typed metadata. In the combined preview, existing physical and HiDPI virtual screens were both captured and received on an iPad; switching sources did not create displays. Independent branch build/test receipts are in the PR.

## 使用方法

保留“镜像／扩展屏”原来的功能。在“镜像”模式下，使用新增的“镜像显示屏”下拉框，选择 Mac 上已有的 G41 或 HiDPI 虚拟显示屏。这个选项只切换捕获来源，不新建显示器。

1194×834 是虚拟屏的逻辑点数，HiDPI 实际像素为 2388×1668。选择原生分辨率时，显示值随所选来源变化。扩展屏仍是独立模式。
