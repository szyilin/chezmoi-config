# Upstream workarounds

临时绕过 Neovim / 生态上游 bug。修复进你使用的 **Neovim stable** 后，删除对应子目录即可。

## `inlay_hint.lua`

**问题**：编辑/格式化/大量删除后偶发

`Decoration provider "win" (ns=nvim.lsp.inlayhint): Invalid 'col': out of range`

**上游**：

- https://github.com/neovim/neovim/issues/36318
- https://github.com/neovim/neovim/issues/39772

**内容**：

| 部分 | 作用 | 上游修好后 |
|------|------|------------|
| A `patch_extmark` | 越界 col 跳过，防 crash | 可留（几乎不触发）或随目录删 |
| B `refresh` autocmd | 编辑后 debounce 刷新 hint | **建议删除**（多余 LSP 请求） |

**验收（修好后可测）**：

1. `:version` 确认已升级含修复的 Neovim
2. 打开 TS/Java 文件，开启 inlay hints（`<leader>uh`）
3. 反复：`dd`、大块删除、格式化 — `:messages` 无 `col: out of range`
4. hints 仍正常显示

**移除**：

1. 删除 `lua/core/workarounds/` 整个目录（含本 README）
2. 删除 `init.lua` 里 `require("core.workarounds.inlay_hint").setup()` 一行
