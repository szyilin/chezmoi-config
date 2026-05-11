# AGENTS

## Chezmoi 工作约定

- 当前仓库就是 `chezmoi` 的源目录。
- 优先在这个仓库内修改配置，不要直接修改 `$HOME` 下的目标文件。
- 修改受管文件后，使用下面的命令同步到目标目录：

```bash
chezmoi apply
```

## 删除受管文件

- 如果某个受 `chezmoi` 管理的文件需要同时从源目录和目标目录删除，优先使用：

```bash
chezmoi destroy <目标路径>
```

- 示例：

```bash
chezmoi destroy ~/.config/zsh/init.zsh
```

- `chezmoi destroy` 比单纯删除源目录文件更合适，因为它会同时删除：
  - 源目录中的条目
  - 目标目录中的真实文件
  - `chezmoi` 的相关状态记录

## 重要说明

- `chezmoi apply` 负责同步现有受管文件的内容变化，但不会自动删除目标目录中已经残留的旧文件。
- 如果某个源文件已经被手动删除，可以使用下面的命令检查目标目录中的残留文件：

```bash
chezmoi unmanaged <路径>
```

- 确认是残留文件后，再手动删除。
