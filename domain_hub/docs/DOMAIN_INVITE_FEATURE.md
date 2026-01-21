# 域名邀请码注册功能 - 使用说明

## 📋 功能概述

这个功能允许管理员为每个根域名单独配置是否需要邀请码才能注册。当启用后：
- 每个用户会自动获得一个10位的随机邀请码
- 用户可以分享邀请码给好友
- 好友使用邀请码才能注册该根域名下的子域名
- 每个邀请码只能使用一次，使用后自动为邀请人刷新新的邀请码
- 管理员可以限制每人最多可邀请多少个好友

---

## 🎯 实现的功能

### 1. **根域名级别的邀请开关**
- 位置：后台 → 根域名白名单 → 编辑根域名
- 每个根域名可以单独开启/关闭邀请注册要求
- 支持混合模式：部分根域名需要邀请码，部分不需要

### 2. **自动邀请码生成**
- 每个用户在每个需要邀请码的根域名下自动获得一个10位邀请码
- 邀请码格式：随机大写字母+数字组合（排除易混淆字符：0, O, I, 1）
- 示例：`A3K9PZ7BM2`

### 3. **前端用户界面**
- 用户前台显示"我的邀请码"区域
- 支持一键复制和分享邀请码
- 注册时选择需要邀请码的根域名会自动显示邀请码输入框

### 4. **邀请码验证**
- 检查邀请码是否存在和有效
- 防止使用自己的邀请码
- 检查邀请人是否达到邀请上限
- 防止重复使用同一根域名的邀请码

### 5. **自动刷新机制**
- 邀请码使用后，系统自动为邀请人生成新的邀请码
- 确保邀请人始终有可用的邀请码

### 6. **后台日志管理**
- 查看所有通过邀请码注册的域名记录
- 支持按邀请码、根域名、用户邮箱搜索
- 显示邀请人和被邀请人信息
- 记录注册IP、注册时间等详细信息

### 7. **邀请限额配置**
- 全局配置：插件配置 → 每人最多可邀请好友数
- 默认限制：每个根域名最多邀请10个好友
- 0表示无限制

### 8. **API支持**
- API注册接口支持邀请码参数 `invite_code`
- 自动验证邀请码有效性
- 返回详细的错误信息

---

## 📊 数据库设计

### 新增表1：`mod_cloudflare_domain_invite_codes`
```sql
-- 存储用户的邀请码
id                  INT          主键
userid              INT          邀请人用户ID
rootdomain          VARCHAR(191) 根域名
code                VARCHAR(20)  邀请码（唯一）
used_count          INT          已使用次数
max_uses            INT          最大使用次数（默认1）
expires_at          DATETIME     过期时间（可选）
status              VARCHAR(20)  状态（active/exhausted/expired）
created_at          DATETIME     创建时间
updated_at          DATETIME     更新时间
```

### 新增表2：`mod_cloudflare_domain_invite_logs`
```sql
-- 记录邀请注册日志
id                  INT          主键
invite_code_id      INT          邀请码ID
code                VARCHAR(20)  使用的邀请码
inviter_userid      INT          邀请人ID
invitee_userid      INT          被邀请人ID
invitee_email       VARCHAR(191) 被邀请人邮箱
rootdomain          VARCHAR(191) 根域名
subdomain           VARCHAR(191) 注册的子域名
subdomain_id        INT          子域名ID
ip_address          VARCHAR(45)  注册IP
created_at          DATETIME     注册时间
```

### 修改表：`mod_cloudflare_rootdomains`
```sql
-- 新增字段
require_invite_code TINYINT(1)   是否需要邀请码注册（默认0）
```

---

## 🔧 技术实现

### 核心文件

#### 1. **服务层** - `lib/Services/DomainInviteService.php`
- `generateInviteCode()` - 生成随机邀请码
- `getUserInviteCode()` - 获取或创建用户邀请码
- `validateInviteCode()` - 验证邀请码
- `useInviteCode()` - 使用邀请码并记录日志
- `isInviteRequired()` - 检查根域名是否需要邀请码
- `getInviteLogs()` - 获取邀请日志

#### 2. **数据库迁移** - `lib/Setup/ModuleInstaller.php`
- 自动创建邀请码表和日志表
- 为根域名表添加邀请码开关字段
- 卸载时自动清理相关表

#### 3. **注册逻辑** - `lib/Services/SubdomainService.php`
- 注册前检查是否需要邀请码
- 验证邀请码有效性
- 注册成功后记录邀请日志
- 支持事务保护

#### 4. **API接口** - `api_handler.php`
- API注册接口增加邀请码验证
- 返回详细的错误信息

#### 5. **后台管理** - `lib/Http/AdminController.php`
- 处理邀请日志查看请求
- 支持搜索和分页

#### 6. **后台操作** - `lib/Services/AdminActionService.php`
- 根域名更新时保存邀请码开关状态

---

## 📱 用户使用流程

### 邀请人（User A）流程：
1. 登录用户前台
2. 在"我的邀请码"区域查看自己的邀请码
3. 点击"复制"或"分享"按钮
4. 将邀请码发送给好友

### 被邀请人（User B）流程：
1. 登录用户前台
2. 选择需要注册的根域名（该根域名已开启邀请注册）
3. 系统自动显示"邀请码"输入框
4. 输入好友给的邀请码
5. 完成其他信息后提交注册
6. 注册成功！

### 管理员流程：
1. 登录WHMCS后台
2. 进入插件管理 → Domain Hub
3. 在"根域名白名单"中点击"编辑"
4. 勾选"需要邀请码注册"
5. 保存设置
6. 点击"查看邀请注册日志"按钮查看所有邀请记录

---

## ⚙️ 配置说明

### 1. 启用邀请注册

**步骤：**
1. 进入WHMCS后台 → 插件模块 → Domain Hub
2. 滚动到"根域名白名单"区域
3. 找到要设置的根域名，点击"编辑"按钮
4. 在弹出的模态框中找到"需要邀请码注册"开关
5. 勾选该选项
6. 点击"保存"

### 2. 配置邀请限额

**步骤：**
1. 进入WHMCS后台 → 设置 → 插件模块
2. 找到Domain Hub，点击"配置"
3. 找到"每人最多可邀请好友数"选项
4. 设置数值（0表示无限制，默认10）
5. 保存配置

### 3. 查看邀请日志

**方法1：**
- URL直接访问：`addonmodules.php?module=domain_hub&action=view_domain_invite_logs`

**方法2：**
- 在根域名管理页面添加"邀请日志"链接

**搜索功能：**
- 按邀请码搜索
- 按根域名搜索
- 按用户邮箱搜索

---

## 🔒 安全特性

### 1. **邀请码唯一性**
- 每个邀请码在全局唯一
- 生成时自动检查重复
- 最多尝试5次生成

### 2. **防滥用机制**
- 每个邀请码只能使用一次
- 不能使用自己的邀请码
- 每人每个根域名只能被邀请一次
- 邀请人达到上限后邀请码失效

### 3. **数据库事务保护**
- 邀请码使用采用悲观锁（lockForUpdate）
- 防止并发使用导致的重复注册
- 注册失败不会扣除邀请次数

### 4. **数据验证**
- 邀请码格式验证（10位字母+数字）
- 根域名匹配验证
- 用户ID有效性验证
- 状态检查（active/exhausted/expired）

---

## 📈 性能优化

### 1. **数据库索引**
自动创建以下索引：
```sql
-- 邀请码表索引
idx_code_unique          (code)                 -- 唯一索引
idx_userid_rootdomain    (userid, rootdomain)   -- 复合索引
idx_status               (status)               -- 状态索引
idx_expires_at           (expires_at)           -- 过期时间索引

-- 邀请日志表索引
idx_code                 (code)                 -- 邀请码索引
idx_inviter              (inviter_userid)       -- 邀请人索引
idx_invitee              (invitee_userid)       -- 被邀请人索引
idx_rootdomain           (rootdomain)           -- 根域名索引
idx_email                (invitee_email)        -- 邮箱索引
idx_created              (created_at)           -- 创建时间索引
```

### 2. **查询优化**
- 使用分页查询避免大数据集加载
- 邀请码验证只查询必要字段
- 支持缓存机制（可选）

### 3. **并发控制**
- 使用数据库事务确保一致性
- 邀请码使用时加锁（lockForUpdate）
- 防止同一邀请码被多次使用

---

## 🐛 故障排查

### 问题1：邀请码输入框不显示
**原因：**
- 根域名未开启邀请注册
- 前端JS加载失败
- ViewModel数据未正确传递

**解决：**
1. 检查根域名设置中的"需要邀请码注册"开关
2. 清除浏览器缓存
3. 检查JS控制台错误

### 问题2：邀请码验证失败
**原因：**
- 邀请码已使用
- 邀请码已过期
- 邀请人达到上限
- 使用了自己的邀请码

**解决：**
1. 检查邀请码状态（后台邀请日志）
2. 确认邀请人配额
3. 使用其他邀请码

### 问题3：邀请码未自动刷新
**原因：**
- 数据库事务失败
- 自动刷新逻辑异常

**解决：**
1. 检查数据库日志
2. 手动为用户重新生成邀请码：
```php
$service = CfDomainInviteService::instance();
$code = $service->getUserInviteCode($userid, $rootdomain);
```

### 问题4：后台日志页面空白
**原因：**
- 数据库表未创建
- AdminController路由未生效

**解决：**
1. 重新激活插件
2. 检查数据库表是否存在
3. 清除模板缓存

---

## 📝 API使用示例

### 注册带邀请码的域名

**请求：**
```bash
POST /modules/addons/domain_hub/api_handler.php
Content-Type: application/json
X-API-Key: cfsd_your_api_key
X-API-Secret: your_api_secret

{
  "subdomain": "mysite",
  "rootdomain": "example.com",
  "invite_code": "A3K9PZ7BM2"
}
```

**成功响应：**
```json
{
  "success": true,
  "message": "Subdomain registered successfully",
  "subdomain_id": 12345,
  "full_domain": "mysite.example.com"
}
```

**失败响应（需要邀请码）：**
```json
{
  "error": "invite code required",
  "message": "该根域名需要邀请码才能注册"
}
```

**失败响应（邀请码无效）：**
```json
{
  "error": "invalid invite code",
  "message": "邀请码不存在或已失效"
}
```

---

## 🔄 升级说明

### 从旧版本升级

1. **备份数据库**
```bash
mysqldump -u用户名 -p数据库名 > backup_before_invite_feature.sql
```

2. **上传新文件**
- 覆盖所有文件到插件目录

3. **重新激活插件**
- WHMCS后台 → 插件模块 → Domain Hub
- 点击"停用"
- 再点击"激活"
- 系统会自动创建所需的数据库表

4. **验证功能**
- 检查根域名编辑界面是否有邀请码开关
- 尝试开启一个根域名的邀请注册
- 在前台查看是否显示邀请码
- 测试注册流程

### 回滚方案

如遇到问题需要回滚：
```sql
-- 删除新增的表
DROP TABLE IF EXISTS `mod_cloudflare_domain_invite_codes`;
DROP TABLE IF EXISTS `mod_cloudflare_domain_invite_logs`;

-- 删除新增的字段
ALTER TABLE `mod_cloudflare_rootdomains` DROP COLUMN `require_invite_code`;

-- 恢复旧版本文件
```

---

## 📊 统计功能（未来扩展）

可以基于现有数据实现：

### 1. 邀请排行榜
```sql
SELECT 
    inviter_userid,
    inviter_email,
    COUNT(*) as invite_count
FROM mod_cloudflare_domain_invite_logs
WHERE rootdomain = 'example.com'
GROUP BY inviter_userid
ORDER BY invite_count DESC
LIMIT 10;
```

### 2. 邀请趋势分析
```sql
SELECT 
    DATE(created_at) as date,
    COUNT(*) as daily_invites
FROM mod_cloudflare_domain_invite_logs
WHERE rootdomain = 'example.com'
    AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(created_at)
ORDER BY date;
```

### 3. 邀请码使用率
```sql
SELECT 
    status,
    COUNT(*) as count
FROM mod_cloudflare_domain_invite_codes
WHERE rootdomain = 'example.com'
GROUP BY status;
```

---

## ✅ 测试清单

在生产环境部署前，请确认以下测试通过：

- [ ] 根域名邀请开关正常开启/关闭
- [ ] 前端正确显示邀请码
- [ ] 邀请码复制功能正常
- [ ] 邀请码输入框在需要时显示
- [ ] 邀请码验证正常工作
- [ ] 不能使用自己的邀请码
- [ ] 邀请码使用后自动刷新
- [ ] 后台日志正常显示
- [ ] 搜索功能正常
- [ ] 分页功能正常
- [ ] API接口支持邀请码
- [ ] 邀请限额配置生效
- [ ] 并发注册不会重复使用邀请码
- [ ] 数据库索引已创建

---

## 💡 最佳实践

### 1. 初始配置建议
- 新站点建议先不开启邀请注册，等有一定用户基础后再开启
- 邀请限额建议设置为5-20人
- 优先为高价值根域名开启邀请注册

### 2. 运营建议
- 定期查看邀请日志，识别活跃邀请者
- 可以考虑给邀请贡献大的用户额外奖励
- 监控异常邀请行为（如IP集中、时间集中）

### 3. 性能建议
- 邀请日志表定期清理（保留近6个月）
- 过期的邀请码定期清理
- 监控数据库表大小

---

## 📞 支持

如有问题，请：
1. 查看本文档的故障排查章节
2. 检查插件日志：`storage/logs/whmcs.log`
3. 检查数据库表结构是否正确
4. 联系技术支持

---

**文档版本：** 1.0  
**更新时间：** 2025-01-21  
**适用插件版本：** Domain Hub v2.2+
