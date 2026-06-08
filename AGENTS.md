# AGENTS

## 强制规则（chezmoi）

1. **只改源目录**：`~/.local/share/chezmoi/`（本仓库）。禁止直接改 `$HOME` 下的目标文件。
2. **改完必须同步**：任何增删改受管文件后，AI **必须执行** `chezmoi apply`，不要只改源目录就结束。
3. **删除用 destroy**：删除受管文件时，AI **必须**用目标路径执行 `chezmoi destroy`，禁止只在源目录 `rm` 就完事。

```bash
chezmoi destroy ~/.config/nvim/init.lua   # 示例：目标路径
chezmoi apply
```

4. **删源后查残留**：从源目录删除文件并 `apply` 后，AI **必须**对对应目录执行 `chezmoi unmanaged`，确认目标目录无残留；有残留则删除目标文件，**禁止**对残留文件执行 `chezmoi add`。
5. **同步前可预览**：不确定时先 `chezmoi diff`，再 `chezmoi apply`。
6. **不怕出错**：源目录有 git，可 `git checkout` / `git revert` 恢复后，再 `chezmoi apply` 把 `$HOME` 同步回来。

## 标准流程

| 操作 | 命令 |
|------|------|
| 修改配置 | 改源 → `chezmoi apply` |
| 删除受管文件 | `chezmoi destroy <目标路径>` → `chezmoi apply` |
| 检查目标残留 | `chezmoi unmanaged ~/.config/<模块>` |
| 预览变更 | `chezmoi diff` |
| 出错回滚 | git 恢复源 → `chezmoi apply` |

## 禁止

- 直接编辑 `~/.config/...` 再 `chezmoi add` 把残留捞回源目录
- 删除源文件却不 `destroy` / 不查 `unmanaged`
- 改完源目录不同步到目标（不跑 `chezmoi apply`）
