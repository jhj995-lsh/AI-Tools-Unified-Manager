# AI 工具统一管理手册 (v2.1)

本文档面向**完全没有技术背景**的用户，教你如何使用统一管理脚本。

---

## 零、首次在新电脑上部署（必读）

如果你刚刚从 GitHub 下载或克隆了这个项目，请按以下步骤操作：

**第 1 步：下载项目**
```powershell
# 方式一：用 Git 克隆（推荐）
git clone https://github.com/jhj995-lsh/AI-Tools-Unified-Manager.git D:\AI

# 方式二：从 GitHub 下载 ZIP，解压到任意文件夹（比如 D:\AI）
```

**第 2 步：进入项目目录**
```powershell
cd D:\AI
```

**第 3 步：运行脚本，环境会自动初始化**
```powershell
.\manage.ps1 status
```
> 首次运行时，脚本会自动创建 `shared\mcp`、`shared\skills`、`backups` 等文件夹，并初始化 Git 版本库。

**第 4 步：修复 AI 工具的链接**
```powershell
.\manage.ps1 repair
```
> 这一步会自动将 Claude、Gemini、Codex 等工具的配置目录链接到共享文件夹，让所有工具共享同一套 MCP 和 Skill。

**第 5 步：验证 MCP 是否可用（可选）**
```powershell
.\manage.ps1 test-mcp
```

> 💡 脚本会自动识别当前用户目录和项目位置，**不需要修改任何路径**，放在任何盘任何文件夹都能运行。

---

## 一、查看整体状态

```powershell
.\manage.ps1 status
```
会告诉你：链接状态、MCP/Skill 数量、Git 状态、备份记录。

---

## 二、查看详细资源

```powershell
.\manage.ps1 list-skills          # 列出所有 Skill
.\manage.ps1 show-skill 技能名称  # 查看某个 Skill 的详情

.\manage.ps1 list-mcp             # 列出所有 MCP 服务器
.\manage.ps1 show-mcp MCP名称     # 查看特定 MCP 配置
```

---

## 三、安装与管理 Skill

```powershell
# 从 GitHub 安装
.\manage.ps1 add-skill https://github.com/用户名/仓库名.git

# 从本地安装
.\manage.ps1 add-skill C:\路径\技能文件夹

# 卸载
.\manage.ps1 remove-skill 技能名称
```

---

## 四、安装与管理 MCP 服务器

```powershell
# 交互式添加（会一步步引导你）
.\manage.ps1 add-mcp

# 卸载（自动从所有 AI 工具配置中移除）
.\manage.ps1 remove-mcp MCP名称

# 测试所有 MCP 能否启动
.\manage.ps1 test-mcp
```

---

## 五、版本管理（Git）

### 首次使用 push/pull 前的准备

`git push` 和 `git pull` 操作的是 `shared` 目录（你的 Skill 和 MCP 配置）。这个目录需要**单独关联一个 GitHub 仓库**：

```powershell
# 1. 在 GitHub 上创建一个新的空仓库（不要勾选 README）
# 2. 关联远程仓库
cd D:\AI\shared
git remote add origin https://github.com/你的用户名/仓库名.git
```

> 💡 关联一次即可，之后就可以直接用 `git push` 和 `git pull` 了。如果忘了这一步，脚本会自动提示你操作步骤。

### 日常使用

```powershell
# 保存当前修改
.\manage.ps1 git save "我修改了什么"

# 一键推送到 GitHub
.\manage.ps1 git push

# 从 GitHub 拉取最新配置到本地（换电脑后同步用）
.\manage.ps1 git pull

# 查看历史记录
.\manage.ps1 git log

# 回滚到某个版本
.\manage.ps1 git rollback 版本号

# 放弃所有未保存的修改
.\manage.ps1 git reset
```

---

## 六、系统维护

```powershell
# 自动修复所有 AI 工具到共享目录的链接
.\manage.ps1 repair

# 手动创建备份（包含配置文件和 shared 文件夹的 zip）
.\manage.ps1 backup

# 查看脚本版本
.\manage.ps1 version
```

---

## 七、编写 Skill 格式规范

`SKILL.md` 文件**必须**以 YAML frontmatter 开头：

```
---
name: 你的技能名称
description: 这个技能是做什么的
---

（正文从这里开始）
```

---

## 快速备忘卡

| 我想要做…             | 命令                                  |
|----------------------|---------------------------------------|
| 首次部署/修复链接      | `.\manage.ps1 repair`                 |
| 看总体状态            | `.\manage.ps1 status`                 |
| 安装 Skill            | `.\manage.ps1 add-skill <来源>`       |
| 添加 MCP              | `.\manage.ps1 add-mcp`                |
| 保存修改              | `.\manage.ps1 git save "说明"`        |
| 推送到 GitHub         | `.\manage.ps1 git push`               |
| 从 GitHub 同步        | `.\manage.ps1 git pull`               |
| 查看历史              | `.\manage.ps1 git log`                |
| 回滚版本              | `.\manage.ps1 git rollback <版本号>`  |
| 测试 MCP              | `.\manage.ps1 test-mcp`               |
| 手动备份              | `.\manage.ps1 backup`                 |
