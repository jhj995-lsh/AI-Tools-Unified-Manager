# AI 工具统一管理手册 (v2.0)

本文档面向**完全没有技术背景**的用户，教你如何使用统一管理脚本。

## 准备工作（只需做一次）

打开 PowerShell，进入管理目录：

```powershell
cd D:\AI
```

> 💡 之后所有命令都在这个目录下运行，每次都要先 `cd D:\AI`。不带任何参数运行 `.\manage.ps1` 即可查看所有可用命令。

---

## 一、查看整体状态

**命令：**
```powershell
.\manage.ps1 status
```

**它会告诉你：**
- 四个 AI 工具（Claude / Gemini / Codex / OpenCode）是否都连接到共享目录 ✅ 或断开 ❌
- 现在有多少个 MCP 服务器、多少个 Skill
- 四个客制化 Skill 是否格式正确
- Git 版本库当前状态与最近的备份

---

## 二、查看详细资源 列表/状态

```powershell
# 查看所有安装的 Skill 列表
.\manage.ps1 list-skills

# 查看某一个 Skill 的详情（例如看前几行 README）
.\manage.ps1 show-skill 技能名称

# 查看所有安装的 MCP 服务器列表
.\manage.ps1 list-mcp

# 查看特定 MCP 的配置详情与是否成功写入 AI 工具
.\manage.ps1 show-mcp MCP名称
```

---

## 三、安装与管理 Skill 技能库 ⬇️

**从 GitHub 安装：**
```powershell
.\manage.ps1 add-skill https://github.com/用户名/仓库名.git
```

**从本地 ZIP 文件或文件夹安装：**
```powershell
.\manage.ps1 add-skill C:\Users\我的文件夹\技能包.zip
.\manage.ps1 add-skill C:\Users\我的文件夹\技能文件夹
```

**卸载特定的 Skill：**
```powershell
.\manage.ps1 remove-skill 技能名称
```

> ✅ 安装和卸载操作会自动保存历史，并且四个 AI 工具会**立刻生效**，无需重启。

---

## 四、安装与管理 MCP 服务器

**交互式添加新 MCP（一步步引导）：**
```powershell
.\manage.ps1 add-mcp
```

**从所有 AI 工具中卸载某个 MCP：**
```powershell
.\manage.ps1 remove-mcp MCP名称
```

**测试当前所有的 MCP 能否正常启动：**
```powershell
.\manage.ps1 test-mcp
```

> ⚙️ 添加和移除 MCP 之后，需要**重启各个 AI 工具的终端**才能生效。

---

## 五、版本管理（Git 防护网）

你对系统做的所有修改都可以被记录和回滚：

### 1. 保存当前所有变更

```powershell
.\manage.ps1 git save "我修改了什么"
```

### 2. 查看历史记录并回滚 🔄

```powershell
# 查看历史记录，寻找最前面的 7 位版本号
.\manage.ps1 git log

# 回滚到指定的版本号
.\manage.ps1 git rollback 版本号
```

> ⚠️ 回滚前会先自动把当前状态备份到一个临时分支，**不会丢失数据**。

### 3. 放弃修改

如果你把文件改乱了想重新来过，直接输入：
```powershell
.\manage.ps1 git reset
```

---

## 六、系统维护与抢救 🚑

如果四个 AI 工具的共享突然断开或崩溃了：

**1. 自动修复连接：**
```powershell
.\manage.ps1 repair
```
这会自动重建所有四个 AI 工具到共享目录的 Junction 链接。

**2. 手动创建急救备份：**
```powershell
.\manage.ps1 backup
```
这会把所有配置文件打包备份到 D:\AI\backups。

**3. 究极紧急回滚（系统完全崩溃时）：**
```powershell
D:\AI\rollback.ps1
```
这会把所有配置文件和目录**完全还原**到 2026-03-10 初始化时的状态。

---

## 七、编写 Skill 格式规范

如果你自己手写 Skill，`SKILL.md` 文件**必须**以这两行开头，否则 Codex 和 Claude 无法识别：

```
---
name: 你的技能名称
description: 这个技能是做什么的
---

（正文从这里开始）
```
