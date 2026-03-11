# AI Tools Unified Manager - Agent 指南

> **⚠️ 给所有阅读此代码库的 AI / Agent 的重要指令：**
> 如果你是 AI 助手（如 Claude、Gemini、Codex 等），并且你正在帮助当前用户操作或开发本项目，请**务必严格遵循以下工作规范**。

## 1. 项目简介与架构规划

本项目是一个统一的 AI 工具管理框架（AI Tools Unified Manager），用于让用户电脑上的不同 AI 编程工具共享同一套 **MCP服务器** (Model Context Protocol Servers) 和 **Skills** (自定义技能)。

**核心设计理念：Junction 符号链接映射**
所有 AI 工具（`.claude`, `.gemini`, `.codex`, `opencode`）的配置和脚本文件夹，**都通过 Junction 符号链接，指向了本项目的 `shared/` 目录**。
你不需要分别去修改每一个 AI 工具的目录，**你所有的读写操作都只应该发生在 `D:\AI\shared` 目录下**。

**目录结构：**
```text
D:\AI\                          # 根目录 (脚本所在位置)
├── manage.ps1                  # 唯一且全能的管理与维护脚本 (核心逻辑)
├── GUIDE.md                    # 写给人类用户看的操作说明 (!你的每次重大改动如果影响用户操作，请同步更新此文件)
├── README.md                   # 本文件，专门写给 AI 代理看的工作规范
├── shared\                     # 被 Git 版本控制追踪的共享目录，所有配置和代码都在这里
│   ├── mcp\                    # 所有的 MCP Server 代码和依赖包放置于此
│   └── skills\                 # 所有的 Skill 技能定义文件放置于此
└── backups\                    # 本地自动备份存放路径
```

---

## 2. 你的工作流与命令规范

**所有的系统维护、状态查询、配置更新，都必须通过 `.\manage.ps1` 脚本进行操作！不要手动去修改那些系统隐藏路径！**

*   想要查看现状：执行 `.\manage.ps1 status`
*   想要修复软链接：执行 `.\manage.ps1 repair`
*   想要给所有工具配置 MCP：执行 `.\manage.ps1 add-mcp` （交互式），或者直接修改代码后再使用它。
*   操作 Skills：执行 `.\manage.ps1 list-skills` 或 `.\manage.ps1 add-skill`
*   测试 MCP 启动是否报错：执行 `.\manage.ps1 test-mcp`

---

## 3. Git 版本控制与多端同步规范

用户使用这个脚手架的一个核心目的是**在多台电脑间同步配置**。
`shared` 文件夹内部本身是一个独立的 Git 仓库，而外层 `D:\AI` 也是一个 Git 仓库。

当你（AI）修改了 `shared\skills\` 或 `shared\mcp\` 里的内容后，请**主动**帮助用户将修改固化并上传：

1.  保存你的修改：
    ```powershell
    .\manage.ps1 git save "你的 commit 提交信息"
    ```
2.  推送到远端备份：
    ```powershell
    .\manage.ps1 git push
    ```
3.  如果用户想同步远端内容：
    ```powershell
    .\manage.ps1 git pull
    ```

> 注意：请使用 `.\manage.ps1 git ...` 系列命令，而不是直接 `cd shared` 然后 `git ...`，以确保行为的一致性和终端反馈的友好度。

---

## 4. Skills 开发与维护守则 (CRITICAL)

当你被要求创建、修改、或优化一个在 `shared\skills\` 目录下的 Skill 时：

1.  **YAML Frontmatter 是必须的：**  
    任何 `SKILL.md` 的前几行**必须是严格的 YAML 格式**，包含 `name` 和 `description`，因为只有这样，Codex 和 Claude Code 才能正确加载和识别它们。
    ```yaml
    ---
    name: this-is-the-skill-name
    description: What this skill does and when to use it
    ---
    ```
    **不可省略分割线 `---`。**

2.  **避免冗余指令：**  
    写给别的 AI 看的 Skill，力求指令清晰、步骤明确，避免模棱两可的形容词。可借助现有的 `writing-skills` 技能来优化。

## 5. MCP 调试与管理规范

MCP Server 往往依赖特定的运行环境（如 Python `uv` 虚拟环境，或 Node.js 环境）。

1.  代码存放：MCP 的核心代码必须放在 `shared\mcp\<MCP名字>\` 下。
2.  测试：开发完 MCP 后，先使用 `.\manage.ps1 test-mcp` 验证它是否会在启动的瞬间崩溃退出。
3.  配置注入：如果用户需要添加新的参数、环境变量，优先指导用户使用 `.\manage.ps1 add-mcp` 让脚本自动将配置分发到所有 4 个 AI 工具的配置文件中（`.claude\.mcp.json`, `.gemini\settings.json`, 等等）。不要让用户手工去改 JSON。

**记住，你的目标是为用户提供高度自动化、优雅且无痛的跨工具 AI 开发体验。**
