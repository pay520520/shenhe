# 根域名邀请功能快速修复指南

## 🚨 如果遇到问题

### 问题1: 点击"根域名邀请"按钮没反应

**症状：** 按钮存在但点击无效，浏览器控制台显示函数未定义

**修复：** 已在代码中修复，更新代码即可

**验证：**
```javascript
// 在浏览器控制台输入
typeof window.showRootdomainInviteCodesModal
// 应该返回: "function"
```

---

### 问题2: 使用邀请码注册时出现数据库错误

**症状：** 
```
Column not found: 1054 Unknown column 'subdomain' in 'field list'
```

**快速修复（3种方法任选其一）：**

#### 方法1: 浏览器访问（最简单）⭐
```
http://你的域名.com/modules/addons/domain_hub/fix_subdomain_column.php
```

#### 方法2: 命令行
```bash
cd /path/to/whmcs/modules/addons/domain_hub
php fix_subdomain_column.php
```

#### 方法3: 直接执行SQL
```sql
ALTER TABLE `mod_cloudflare_rootdomain_invite_logs` 
ADD COLUMN `subdomain` VARCHAR(255) NULL DEFAULT NULL 
AFTER `invitee_email`;
```

**验证：**
```sql
DESCRIBE mod_cloudflare_rootdomain_invite_logs;
```
看到 `subdomain` 字段即表示成功。

---

## 📋 快速检查清单

```bash
# 1. 检查文件是否存在
[ -f templates/client/partials/modals.tpl ] && echo "✓ 模板文件存在" || echo "✗ 模板文件缺失"

# 2. 检查修复脚本是否存在
[ -f fix_subdomain_column.php ] && echo "✓ 修复脚本存在" || echo "✗ 修复脚本缺失"

# 3. 检查服务文件是否更新
grep -q "表存在但可能缺少 subdomain 字段" lib/Services/RootdomainInviteService.php && echo "✓ 服务已更新" || echo "✗ 服务需要更新"
```

---

## 🎯 完整修复步骤

### Step 1: 更新代码
```bash
# 确保所有文件都是最新版本
git pull origin your-branch
# 或从备份恢复最新文件
```

### Step 2: 运行修复脚本
```bash
# 方式A: 浏览器访问
# http://你的域名.com/modules/addons/domain_hub/fix_subdomain_column.php

# 方式B: 命令行
cd modules/addons/domain_hub
php fix_subdomain_column.php
```

### Step 3: 验证修复
```bash
# 测试1: 点击根域名邀请按钮，应该能打开弹窗
# 测试2: 使用邀请码注册域名，应该成功
# 测试3: 查看邀请历史，应该显示注册的域名
```

---

## 📞 需要帮助？

### 查看详细文档
- **按钮问题：** `BUG_FIX_ROOTDOMAIN_INVITE.md`
- **字段问题：** `FIX_SUBDOMAIN_COLUMN_ERROR.md`
- **代码审查：** `CODE_REVIEW_REPORT.md`
- **中文说明：** `问题修复说明.md`

### 常见问题

**Q: 修复脚本访问显示404**  
A: 确认路径正确，文件在 `modules/addons/domain_hub/fix_subdomain_column.php`

**Q: SQL执行失败**  
A: 检查数据库权限，确保有 ALTER TABLE 权限

**Q: 修复后还是报错**  
A: 清除缓存，或重启 PHP-FPM / Apache

**Q: 如何回滚**  
A: 删除 subdomain 字段：
```sql
ALTER TABLE `mod_cloudflare_rootdomain_invite_logs` DROP COLUMN `subdomain`;
```

---

## ✅ 成功标志

修复成功后，你应该能：

1. ✅ 点击"根域名邀请"按钮打开弹窗
2. ✅ 看到每个根域名的邀请码
3. ✅ 复制邀请码
4. ✅ 使用邀请码成功注册域名
5. ✅ 在邀请历史中看到注册的域名

---

**最后更新：** 2024-01-21  
**版本：** 修复版  
**状态：** ✅ 所有问题已解决
