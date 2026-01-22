# 修复 subdomain 字段缺失错误

## 错误信息

```
SQLSTATE[42S22]: Column not found: 1054 Unknown column 'subdomain' in 'field list' 
(SQL: insert into `mod_cloudflare_rootdomain_invite_logs` 
(`rootdomain`, `invite_code`, `inviter_userid`, `invitee_userid`, 
`invitee_email`, `subdomain`, `invitee_ip`, `created_at`, `updated_at`) 
values (cc.cd, HJ6NUE24GA, 2, 4, pay520@gmail.com, 1251251025.cc.cd, , 
2026-01-21 23:37:47, 2026-01-21 23:37:47))
```

## 问题原因

根域名邀请日志表 `mod_cloudflare_rootdomain_invite_logs` 是在早期版本创建的，当时没有 `subdomain` 字段。后来的代码更新添加了这个字段的使用，但已有的数据库表没有更新。

## 影响范围

- 使用根域名邀请码注册域名时会失败
- 显示数据库错误信息
- 邀请码功能无法正常工作

## 解决方案

### 方案一：自动修复（推荐）⭐

代码已经更新，现在会自动检测并添加缺失的字段。只需要触发一次检查：

**方法1：通过前端访问**
1. 访问域名管理页面
2. 点击"根域名邀请"按钮
3. 系统会自动检测并添加缺失字段

**方法2：通过后台操作**
1. 后台访问根域名邀请管理页面
2. 系统会自动检测并添加缺失字段

### 方案二：运行修复脚本

**通过浏览器访问：**
```
http://你的域名.com/modules/addons/domain_hub/fix_subdomain_column.php
```

**通过命令行：**
```bash
cd /path/to/whmcs/modules/addons/domain_hub
php fix_subdomain_column.php
```

**输出示例：**
```
修复根域名邀请日志表
==================================================

[1/3] 检查表是否存在...
      ✓ 表存在

[2/3] 检查 subdomain 字段...
      ⚠ 字段不存在，需要添加

[3/3] 添加 subdomain 字段...
      ✓ 字段添加成功

==================================================
修复完成！现在可以正常使用根域名邀请功能了。
```

### 方案三：手动执行SQL

**方法1：检查后添加**
```sql
-- 检查字段是否存在
SELECT COLUMN_NAME 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'mod_cloudflare_rootdomain_invite_logs'
AND COLUMN_NAME = 'subdomain';

-- 如果不存在，执行添加
ALTER TABLE `mod_cloudflare_rootdomain_invite_logs` 
ADD COLUMN `subdomain` VARCHAR(255) NULL DEFAULT NULL 
AFTER `invitee_email`;
```

**方法2：直接执行迁移SQL**
```bash
mysql -u your_username -p your_database < migrations/add_subdomain_to_rootdomain_invite_logs.sql
```

## 修复验证

### 1. 检查字段是否存在

**SQL查询：**
```sql
DESCRIBE mod_cloudflare_rootdomain_invite_logs;
```

**期望输出：**
```
+------------------+------------------+------+-----+---------+
| Field            | Type             | Null | Key | Default |
+------------------+------------------+------+-----+---------+
| id               | int(10) unsigned | NO   | PRI | NULL    |
| rootdomain       | varchar(255)     | NO   | MUL | NULL    |
| invite_code      | varchar(10)      | NO   | MUL | NULL    |
| inviter_userid   | int(10) unsigned | NO   | MUL | NULL    |
| invitee_userid   | int(10) unsigned | YES  | MUL | NULL    |
| invitee_email    | varchar(191)     | YES  | MUL | NULL    |
| subdomain        | varchar(255)     | YES  |     | NULL    |  ← 应该存在
| invitee_ip       | varchar(64)      | YES  |     | NULL    |
| created_at       | timestamp        | YES  | MUL | NULL    |
| updated_at       | timestamp        | YES  |     | NULL    |
+------------------+------------------+------+-----+---------+
```

### 2. 功能测试

**测试步骤：**
1. 登录 WHMCS 客户端
2. 进入域名管理页面
3. 点击"注册新域名"
4. 选择需要邀请码的根域名
5. 输入有效的邀请码
6. 提交注册

**期望结果：**
- ✅ 注册成功
- ✅ 数据库中记录包含 subdomain 字段
- ✅ 邀请人可以在历史记录中看到邀请的域名

**测试SQL：**
```sql
-- 查看最新的邀请记录
SELECT * FROM mod_cloudflare_rootdomain_invite_logs 
ORDER BY id DESC 
LIMIT 5;
```

## 技术细节

### 修改的文件

1. **lib/Services/RootdomainInviteService.php**
   - 修改了 `ensureTables()` 方法
   - 添加了自动检测和修复逻辑
   - 代码行数：第59-66行

2. **新增文件：**
   - `fix_subdomain_column.php` - 快速修复脚本
   - `migrations/add_subdomain_to_rootdomain_invite_logs.sql` - SQL迁移脚本
   - `migrate_rootdomain_invite_logs.php` - PHP迁移脚本

### 自动修复逻辑

```php
// 表存在但可能缺少 subdomain 字段（旧版本升级）
if (!Capsule::schema()->hasColumn(self::TABLE_LOGS, 'subdomain')) {
    Capsule::schema()->table(self::TABLE_LOGS, function ($table) {
        $table->string('subdomain', 255)->nullable()->after('invitee_email');
    });
}
```

这段代码会在每次调用 `ensureTables()` 时自动检查并添加缺失的字段。

### 字段规格

- **字段名：** `subdomain`
- **类型：** VARCHAR(255)
- **允许NULL：** YES
- **默认值：** NULL
- **位置：** 在 `invitee_email` 字段之后

### 为什么需要这个字段？

`subdomain` 字段用于记录被邀请人注册的具体域名，这样：

1. **追踪功能：** 邀请人可以看到通过他的邀请码注册了哪些域名
2. **统计分析：** 管理员可以分析邀请转化率
3. **审计日志：** 完整记录邀请关系链
4. **问题排查：** 出现问题时可以追溯到具体域名

## 常见问题

### Q1: 为什么会出现这个问题？

**A:** 表是在添加此功能之前创建的。代码更新添加了对 `subdomain` 字段的使用，但现有数据库没有自动更新。

### Q2: 修复后会影响现有数据吗？

**A:** 不会。新字段允许NULL值，已有记录会自动填充NULL，不影响现有功能。

### Q3: 如果不修复会怎样？

**A:** 根域名邀请功能完全无法使用，用户尝试使用邀请码注册会看到数据库错误。

### Q4: 修复需要停机吗？

**A:** 不需要。添加字段是在线操作，不影响正在运行的服务。

### Q5: 如何确认修复成功？

**A:** 
- 运行修复脚本看到成功消息
- 或使用 `DESCRIBE mod_cloudflare_rootdomain_invite_logs` 查看表结构
- 或尝试使用邀请码注册域名

### Q6: 可以删除修复脚本吗？

**A:** 修复完成后可以删除 `fix_subdomain_column.php`，但建议保留 `migrations/` 目录中的SQL文件作为文档。

## 预防措施

### 对于开发者

1. **数据库迁移：** 未来如果修改表结构，应该提供迁移脚本
2. **版本检查：** 添加版本号跟踪，便于识别需要升级的实例
3. **自动修复：** 关键功能应该包含自动检测和修复逻辑（已实现）

### 对于管理员

1. **定期备份：** 执行任何数据库修改前先备份
2. **测试环境：** 在测试环境先验证修复方案
3. **监控日志：** 关注错误日志，及时发现类似问题

## 回滚方案

如果修复后出现问题，可以回滚：

```sql
-- 删除添加的字段
ALTER TABLE `mod_cloudflare_rootdomain_invite_logs` 
DROP COLUMN `subdomain`;
```

⚠️ **注意：** 删除字段会丢失该字段的所有数据，请谨慎操作！

## 总结

- ✅ 问题已识别：表缺少 `subdomain` 字段
- ✅ 自动修复已实现：代码会自动检测并添加字段
- ✅ 手动修复可用：提供了多种修复方案
- ✅ 修复过程安全：不影响现有数据
- ✅ 文档完整：包含详细的说明和验证步骤

---

**更新日期：** 2024-01-21  
**问题状态：** 已修复  
**修复方式：** 自动修复 + 手动脚本  
**影响版本：** 所有在 subdomain 字段添加前创建表的版本
