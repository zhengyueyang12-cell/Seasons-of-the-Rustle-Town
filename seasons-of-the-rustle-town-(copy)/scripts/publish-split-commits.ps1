#Requires -Version 5.1
<#
.SYNOPSIS
    将 Seasons of the Rustle Town 的 Godot 改动拆成 5 个主题提交并推送到 GitHub。

.DESCRIPTION
    适用于首次把本项目纳入 Git 管理。每个提交聚焦一个子系统，提交说明写给第一次读仓库的人。

.PARAMETER RemoteUrl
    GitHub 仓库地址，例如 https://github.com/you/Seasons-of-the-Rustle-Town.git

.PARAMETER Branch
    推送分支，默认 main。

.PARAMETER SkipPush
    只创建本地提交，不 push。

.EXAMPLE
    .\scripts\publish-split-commits.ps1 -RemoteUrl "https://github.com/you/Seasons-of-the-Rustle-Town.git"
#>
param(
    [string]$RemoteUrl = "",
    [string]$Branch = "main",
    [switch]$SkipPush
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

function Require-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error @"
未检测到 Git。请先安装 Git for Windows 并确保 git 在 PATH 中：
  https://git-scm.com/download/win
安装后重新打开终端，再运行本脚本。
"@
    }
}

function Invoke-GitCommit {
    param(
        [string]$Subject,
        [string]$Body
    )
    git add -A
    $staged = git diff --cached --name-only
    if (-not $staged) {
        Write-Warning "跳过空提交: $Subject"
        return
    }
    git commit -m $Subject -m $Body
    Write-Host "OK  $Subject" -ForegroundColor Green
}

Require-Git

if (-not (Test-Path ".git")) {
    git init -b $Branch
    Write-Host "已初始化 Git 仓库 (分支: $Branch)" -ForegroundColor Cyan
}

# 若已有提交，提示用户
$existing = git rev-parse --verify HEAD 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Warning "仓库已有提交历史。本脚本面向「首次提交」。若继续，可能产生重复提交。"
    $confirm = Read-Host "继续? (y/N)"
    if ($confirm -ne "y") { exit 0 }
}

# ── 提交 1：美术资源与目录规范 ─────────────────────────────────────────
git add -A
git reset

git add .gitignore
git add icon.svg
git add art/
git add resources/sprites/
git add Scenes/world/
git add Scenes/props/buildings/
git add Scenes/props/furniture/

Invoke-GitCommit -Subject "chore(art): organize raw assets under art/ directory" -Body @"
为什么有这次提交
----------------
把散落在 Assets/、terrains/、sprites/ 的原始贴图，统一迁到 art/ 下，
让新人一眼能分清：哪些是美术源文件，哪些是场景/脚本。

目录约定（给第一次打开项目的人）
--------------------------------
art/world/terrain/     地块、草地、道路贴图（给 TileMap 用）
art/world/nature/      树木等自然环境素材
art/world/props/       篝火、花盆、复古屏幕等场景装饰
art/characters/player/ 玩家行走/奔跑精灵
art/items/tools/       锄头、斧头、镐子
art/items/weapons/     剑类武器
art/items/consumables/ 药水等消耗品图标

resources/sprites/     预留给 SpriteFrames（动画配置）
Scenes/props/buildings|furniture/  预留给可放置建筑/家具预制体
Scenes/world/areas/    预留给 farm.tscn、town.tscn 等分区场景

注意
----
*.import 不入库（见 .gitignore）。克隆后首次用 Godot 打开会自动重新导入贴图。
此时尚未提交 project.godot，需完成全部 5 个提交后项目才可运行。
"@

# ── 提交 2：核心框架（玩家、背包、时间、UI）────────────────────────────
git add -A
git reset

git add autoloads/item_registry.gd
git add autoloads/item_registry.gd.uid
git add autoloads/game_state.gd
git add autoloads/game_state.gd.uid
git add autoloads/inventory_manager.gd
git add autoloads/inventory_manager.gd.uid
git add autoloads/input_manager.gd
git add autoloads/input_manager.gd.uid
git add autoloads/time_manager.gd
git add autoloads/time_manager.gd.uid
git add autoloads/ui_manager.gd
git add autoloads/ui_manager.gd.uid
git add resources/item_resource.gd
git add resources/item_resource.gd.uid
git add resources/healthpotion.tres
git add GDScripts/player_movement.gd
git add GDScripts/player_movement.gd.uid
git add GDScripts/camera_follow.gd
git add GDScripts/camera_follow.gd.uid
git add GDScripts/ui_layer.gd
git add GDScripts/ui_layer.gd.uid
git add GDScripts/game_manager.gd
git add GDScripts/game_manager.gd.uid
git add animation_state_machine.gd
git add animation_state_machine.gd.uid
git add item_pickup.gd
git add item_pickup.gd.uid
git add Scenes/player.tscn
git add Scenes/slot.tscn
git add Scenes/health_potion.tscn

Invoke-GitCommit -Subject "feat(core): add player, inventory, time, and UI foundation" -Body @"
这个提交解决什么问题
--------------------
建立类星露谷游戏的最小可运行骨架：玩家能移动、背包能装东西、
时间流逝、UI 能显示金钱/体力/日期。

关键 Autoload（全局单例，在 project.godot 注册）
-------------------------------------------------
GameState         金币、体力、当前装备 ID
InventoryManager  背包格子与堆叠逻辑
InputManager      WASD、E 交互、1-8 热键、左键攻击
TimeManager       游戏内日/季/年推进
ItemRegistry      物品数据注册表
UIManager         HUD 刷新

场景入口
--------
Scenes/player.tscn   玩家角色（移动 + 动画状态机）
Scenes/slot.tscn     背包格子 UI
item_pickup.gd       地面拾取物通用逻辑

操作（当前版本）
----------------
WASD 移动 | Tab 背包 | 1-8 热键 | 走近拾取物自动捡起

说明
----
project.godot 与 main.tscn 在最后一个提交中一并加入，确保 Autoload 与场景同步注册。
"@

# ── 提交 3：地形破坏 + 云朵阴影 ─────────────────────────────────────────
git add -A
git reset

git add systems/terrain_system/
git add shaders/

Invoke-GitCommit -Subject "feat(terrain): add tile destruction and cloud shadow shader" -Body @"
这个提交解决什么问题
--------------------
实现「锄地」核心玩法：把草地瓦片替换成泥土，并自动刷新边缘融合贴图；
同时给地图加一层流动的云朵阴影，增强 2D 俯视角氛围。

核心脚本
--------
systems/terrain_system/tile_destructor.gd
  - destroy_tile_at_position()  在鼠标/玩家朝向位置破坏瓦片
  - 支持圆形/方形范围、Terrain Set 自动连接（Peering）
  - 挂在 main.tscn 的 World/TileDestructor，组名 tile_destructor

shaders/cloudshadow.gdshader
  - 多层噪声斜向流动的半透明阴影
  - 挂在 TileMapLayerGround/CloudShadow ColorRect 上

依赖关系
--------
ToolController（下一提交）在玩家按 E 时调用 TileDestructor。
地形层使用 art/world/terrain/ 下的 Farm、meadow 贴图。
"@

# ── 提交 4：武器与工具 + 热键栏 ─────────────────────────────────────────
git add -A
git reset

git add autoloads/weapon_registry.gd
git add autoloads/weapon_registry.gd.uid
git add autoloads/tool_registry.gd
git add autoloads/tool_registry.gd.uid
git add resources/weapon_resource.gd
git add resources/weapon_resource.gd.uid
git add resources/tool_resource.gd
git add resources/tool_resource.gd.uid
git add resources/weapons/
git add resources/tools/wooden_hoe.tres
git add resources/tools/stone_pickaxe.tres
git add GDScripts/weapon_manager.gd
git add GDScripts/weapon_manager.gd.uid
git add GDScripts/tool_manager.gd
git add GDScripts/tool_manager.gd.uid
git add GDScripts/combat_controller.gd
git add GDScripts/combat_controller.gd.uid
git add GDScripts/tool_controller.gd
git add GDScripts/tool_controller.gd.uid
git add GDScripts/equipment_controller.gd
git add GDScripts/equipment_controller.gd.uid
git add GDScripts/held_item_visual.gd
git add GDScripts/held_item_visual.gd.uid
git add Scenes/tools/stone_pickaxe.tscn
git add Scenes/wooden_sword.tscn

Invoke-GitCommit -Subject "feat(equipment): add hotbar weapons, tools, and held-item visuals" -Body @"
这个提交解决什么问题
--------------------
把「武器」和「工具」从玩家身上解耦成数据驱动系统：
背包热键栏切换装备，手持物显示在玩家旁边并随朝向翻转。

架构一览
--------
resources/weapons/*.tres   武器数据（伤害、攻速、贴图）
resources/tools/*.tres     工具数据（类型、体力消耗、范围）
WeaponRegistry / ToolRegistry   启动时扫描目录并注册到 ItemRegistry

玩家节点上的组件
----------------
EquipmentController  热键 1-8 切换背包前 8 格，决定当前拿武器还是工具
WeaponManager      武器视觉与 GameState 同步
ToolManager        工具视觉与 GameState 同步
CombatController   左键攻击（持工具时禁用）
ToolController     E 键使用工具（锄头等）
HeldItemVisual     根据朝向镜像武器/工具位置

操作
----
1-8 切换热键 | 持武器时左键攻击 | 持锄头时 E 锄地
开局 game_manager 赠送木锄 + 细剑
"@

# ── 提交 5：树木砍伐 + 生态再生 + 主场景整合 ───────────────────────────
git add -A
git reset

# 剩余全部文件
git add -A

Invoke-GitCommit -Subject "feat(trees): add tree chopping, ecology, and main world layout" -Body @"
这个提交解决什么问题
--------------------
实现完整的类星露谷式树木系统：五阶段生长、斧头砍伐、倒下掉落、
树桩清理、农场/野外不同再生规则，以及主场景中的示例布置。

树木系统（systems/tree_system/）
--------------------------------
tree_entity.gd       五阶段精灵、受击震动、倒下动画、树桩阶段再砍掉落
tree_chop_detector.gd  根据玩家位置/朝向查找最近可砍目标
drop_spawner.gd      沿倒下方向散落生成地面掉落物
farm_zone.gd         Area2D 标记农场范围（影响再生规则）

资源与物品
----------
resources/trees/oak_tree.tres   各阶段贴图、砍伐次数、掉落量
resources/items/wood.tres       木材
resources/items/tree_sap.tres   树液
resources/items/tree_seed.tres  树种（E 种在锄过的地上）
resources/tools/wooden_axe.tres 木斧（左键砍树）

Autoload
--------
TreeRegenerationService
  - 每晚：农场内成熟树周围 15% 几率长种子；野外清树桩后 20% 几率长树苗
  - 周围 8 格有成熟树时，幼树停止生长

主场景 Scenes/main.tscn
-----------------------
World/TileMapLayerGround   地形
World/FarmZone             农场区域（可编辑器调整范围）
World/YSort_Objects/Trees  示例树（农场内 + 野外各一棵）
World/YSort_Objects/Drops  地面掉落物容器
World/YSort_Objects/Items  可拾取工具/药水

操作
----
热键选木斧 → 靠近大树左键砍（5 次倒树）→ 再砍树桩
持树种 + 锄地后按 E 种植
GameState.foraging_level / luck 影响掉落数量

本提交还包含
--------------
project.godot   注册全部 Autoload 与输入映射（项目入口配置）
Scenes/main.tscn  主世界场景（地形、玩家、UI、示例物体）
其余未归入前 4 次提交的文件
"@

# ── 推送 ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "提交完成。历史记录：" -ForegroundColor Cyan
git log --oneline

if ($SkipPush) {
    Write-Host "已跳过推送 (-SkipPush)。" -ForegroundColor Yellow
    exit 0
}

if ([string]::IsNullOrWhiteSpace($RemoteUrl)) {
    $RemoteUrl = Read-Host "请输入 GitHub 仓库 URL（留空则只保留本地提交）"
}

if ([string]::IsNullOrWhiteSpace($RemoteUrl)) {
    Write-Host "未配置远程，仅保留本地提交。" -ForegroundColor Yellow
    exit 0
}

$remotes = git remote 2>$null
if ($remotes -notcontains "origin") {
    git remote add origin $RemoteUrl
}

git push -u origin $Branch
Write-Host "已推送到 $RemoteUrl ($Branch)" -ForegroundColor Green
