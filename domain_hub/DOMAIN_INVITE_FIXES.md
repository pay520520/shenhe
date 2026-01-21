# 域名邀请码功能修复说明

## 问题描述

用户反馈了两个问题：
1. **前端不显示邀请码提示**：后台开启邀请码功能后，前端注册表单不显示邀请码输入框
2. **后台没有邀请日志入口**：无法查看邀请注册域名日志

## 修复内容

### 1. 前端邀请码显示修复

#### 修改的文件：

**lib/Services/ClientViewModelBuilder.php**
- 添加 `loadRootInviteRequiredMap()` 方法：加载哪些根域名需要邀请码
- 添加 `loadDomainInviteCodes()` 方法：为用户加载所有需要邀请码的根域名的邀请码
- 在 `build()` 方法中添加两个新的全局变量：
  - `rootInviteRequiredMap`: 根域名邀请码要求映射
  - `domainInviteCodes`: 用户的域名邀请码集合

**templates/client/partials/modals.tpl**
- 在注册表单中添加邀请码输入框（默认隐藏）
- 字段包含：
  - 邀请码输入框（10位，大写字母）
  - 提示信息
  - 必填标记（当需要时）

**templates/client/partials/scripts.tpl**
- 添加 `ROOT_INVITE_REQUIRED_MAP` JS常量
- 添加 `updateInviteCodeField()` 函数：根据选择的根域名动态显示/隐藏邀请码输入框
- 修改 `rootSelect.addEventListener('change')` 事件：当用户选择根域名时自动检查是否需要邀请码

**templates/client/partials/quota_invite.tpl**
- 在配额信息卡片下方添加"我的域名邀请码"卡片
- 显示用户所有需要邀请码的根域名及其对应的邀请码
- 提供一键复制功能
- 显示邀请码使用情况（已使用/总数）
- 添加使用提示信息

#### 功能流程：

1. 用户打开注册表单
2. 选择根域名下拉框
3. JS检查该根域名是否需要邀请码（通过`ROOT_INVITE_REQUIRED_MAP`）
4. 如果需要，显示邀请码输入框并设置为必填
5. 如果不需要，隐藏邀请码输入框并移除必填要求
6. 用户输入邀请码后提交表单
7. 后端验证邀请码有效性

### 2. 后台邀请日志入口修复

#### 修改的文件：

**templates/admin.tpl**
- 在后台首页添加"域名邀请注册功能"卡片
- 包含"查看邀请注册日志"按钮
- 链接到 `?module=domain_hub&action=view_domain_invite_logs`
- 添加功能说明文字

**lib/Http/AdminController.php**
- 已在之前的实现中添加了 `handleViewDomainInviteLogs()` 方法
- 处理GET请求，读取搜索参数（邀请码、根域名、用户邮箱）
- 调用 `CfDomainInviteService::getInviteLogs()` 获取日志
- 渲染 `admin_invite_logs.tpl` 模板

**templates/admin/partials/domain_invite_logs.tpl**
- 显示邀请注册日志列表
- 支持搜索功能（邀请码、根域名、用户邮箱）
- 显示详细信息：邀请人、被邀请人、注册的域名、IP、时间等
- 分页导航
- 使用说明和提示信息

**templates/admin_invite_logs.tpl**
- 独立页面模板
- 包含返回按钮
- 引入 Bootstrap 和 Font Awesome 样式
- 包含 `domain_invite_logs.tpl` partial

### 3. 系统集成修复

**lib/autoload.php**
- 添加 `CfDomainInviteService` 到自动加载映射
- 确保服务类在需要时能被正确加载

## 测试步骤

### 前端测试：

1. **开启邀请码功能**
   ```
   后台 → 根域名白名单 → 编辑根域名 → 勾选"需要邀请码注册"
   ```

2. **前端查看邀请码**
   - 登录用户前台
   - 应该看到"我的域名邀请码"卡片（如果有需要邀请码的根域名）
   - 显示邀请码和使用情况

3. **测试注册流程**
   - 点击"注册新域名"按钮
   - 选择需要邀请码的根域名
   - 应该自动显示"邀请码"输入框（带*必填标记）
   - 输入框应该是大写字母，最多10位
   - 不输入邀请码提交应该提示"该根域名需要邀请码才能注册"

4. **测试邀请码切换**
   - 在注册表单中切换不同的根域名
   - 需要邀请码的显示输入框
   - 不需要邀请码的隐藏输入框

5. **测试邀请码复制**
   - 点击"复制"按钮
   - 应该提示"邀请码已复制"
   - 粘贴到邮件/聊天中验证

### 后台测试：

1. **查看邀请日志入口**
   - 登录WHMCS后台
   - 进入 插件模块 → Domain Hub
   - 应该看到"域名邀请注册功能"卡片
   - 点击"查看邀请注册日志"按钮

2. **查看日志列表**
   - 应该看到所有通过邀请码注册的记录
   - 包含：邀请码、邀请人、被邀请人、根域名、子域名、IP、时间

3. **测试搜索功能**
   - 按邀请码搜索
   - 按根域名搜索
   - 按用户邮箱搜索
   - 测试分页功能

4. **测试邀请码开关**
   - 编辑根域名
   - 开启/关闭"需要邀请码注册"开关
   - 保存后在前端验证是否生效

## 已知限制

1. **邀请码长度固定**：目前邀请码固定为10位，不可配置
2. **邀请码自动刷新**：每个邀请码使用一次后自动刷新，不支持多次使用
3. **邀请限额**：通过插件配置设置，默认每人可邀请10个好友（每个根域名）
4. **邀请统计**：目前只有基础日志，没有统计图表

## 后续优化建议

1. **增强用户体验**
   - 添加邀请码分享链接（直接填充邀请码）
   - 生成邀请二维码
   - 添加邀请成功通知

2. **增强管理功能**
   - 邀请统计报表（按时间、按用户、按根域名）
   - 邀请排行榜
   - 批量管理邀请码

3. **性能优化**
   - 邀请码缓存机制
   - 日志定期归档
   - 索引优化

4. **安全增强**
   - 邀请码使用频率限制（防止暴力尝试）
   - IP白名单/黑名单
   - 异常邀请行为检测

## 文件变更清单

### 新增文件：
- `lib/Services/DomainInviteService.php` - 邀请码服务类
- `templates/admin/partials/domain_invite_logs.tpl` - 后台日志列表模板
- `templates/admin_invite_logs.tpl` - 后台日志独立页面模板
- `docs/DOMAIN_INVITE_FEATURE.md` - 功能完整文档

### 修改文件：
- `lib/autoload.php` - 添加自动加载
- `lib/Services/ClientViewModelBuilder.php` - 添加邀请码数据加载
- `lib/Services/SubdomainService.php` - 添加邀请码验证
- `lib/Services/AdminActionService.php` - 添加邀请码开关保存
- `lib/Http/AdminController.php` - 添加日志查看处理
- `lib/Setup/ModuleInstaller.php` - 添加数据库表创建
- `api_handler.php` - API支持邀请码
- `domain_hub.php` - 添加配置项
- `templates/admin.tpl` - 添加日志入口
- `templates/admin/partials/rootdomains/list.tpl` - 添加邀请码列和开关
- `templates/client/partials/modals.tpl` - 添加邀请码输入框
- `templates/client/partials/scripts.tpl` - 添加前端逻辑
- `templates/client/partials/quota_invite.tpl` - 添加邀请码显示卡片

## 数据库变更

### 新增表：
1. `mod_cloudflare_domain_invite_codes` - 邀请码表
2. `mod_cloudflare_domain_invite_logs` - 邀请日志表

### 修改表：
1. `mod_cloudflare_rootdomains` - 添加 `require_invite_code` 字段

## 配置说明

### 插件配置项：
- **每人最多可邀请好友数**：限制每个用户在每个根域名下最多可邀请多少人（0表示无限制，默认10）

### 根域名配置：
- **需要邀请码注册**：开关选项，控制该根域名是否需要邀请码才能注册

## 版本信息

- 修复日期：2025-01-21
- 适用版本：Domain Hub v2.2+
- PHP要求：>= 7.4
- WHMCS要求：>= 7.0

## 支持

如有问题，请查看：
1. `/docs/DOMAIN_INVITE_FEATURE.md` - 完整功能文档
2. WHMCS错误日志：`storage/logs/whmcs.log`
3. 数据库表结构验证：检查表是否正确创建
