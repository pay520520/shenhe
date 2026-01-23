# 同步间隔上限修改指南

## 🎯 修改建议

### 推荐的上限值

| 上限值 | 天数 | 适用场景 |
|--------|------|----------|
| **1440** | 1天 | 当前默认值，适合中小型部署 |
| **4320** | 3天 | 适合大型低频变更场景 |
| **10080** | 7天 | 适合超大型或稳定环境 |
| **43200** | 30天 | 仅用于归档/只读环境 |

### ⚠️ 不推荐的值

- ❌ **999999分钟（694天）**：太长，无实际意义
- ❌ **超过30天**：可能导致任务调度异常
- ❌ **小于30分钟**：高负载，不适合生产环境

---

## 📝 修改步骤

### 1️⃣ 修改自动同步上限

**文件**: `hooks.php`  
**位置**: 第36行

#### 示例1：改为7天（10080分钟）

```php
// 修改前
$intervalMin = max(5, min(1440, $intervalMin));

// 修改后
$intervalMin = max(5, min(10080, $intervalMin));
```

#### 示例2：改为3天（4320分钟）

```php
$intervalMin = max(5, min(4320, $intervalMin));
```

#### 示例3：改为30天（43200分钟）

```php
$intervalMin = max(5, min(43200, $intervalMin));
```

---

### 2️⃣ 修改风险扫描上限

**文件**: `hooks.php`  
**位置**: 第71行

```php
// 修改前
$scanIntervalMin = max(15, min(1440, $scanIntervalMin));

// 修改后（改为7天）
$scanIntervalMin = max(15, min(10080, $scanIntervalMin));
```

---

### 3️⃣ 修改域名清理间隔上限

**文件**: `hooks.php`  
**位置**: 第290-296行

```php
// 修改前
if ($cleanupIntervalHours < 1) {
    $cleanupIntervalHours = 1;
} elseif ($cleanupIntervalHours > 168) {
    $cleanupIntervalHours = 168;
}

// 修改后（改为30天 = 720小时）
if ($cleanupIntervalHours < 1) {
    $cleanupIntervalHours = 1;
} elseif ($cleanupIntervalHours > 720) {
    $cleanupIntervalHours = 720;
}
```

---

## ⚠️ 修改后的影响

### ✅ 正面影响

1. **更灵活的配置**：可以根据实际需求设置更长的间隔
2. **降低服务器负载**：超大型部署可以延长同步间隔
3. **满足特殊场景**：稳定环境可以减少不必要的同步

### ⚠️ 需要注意

1. **实时性降低**：间隔越长，DNS记录同步延迟越大
2. **问题发现延迟**：异常情况可能更晚被发现
3. **任务积压风险**：如果间隔过长后又改短，可能导致任务堆积

---

## 🧪 测试验证

### 1. 修改代码后测试

```bash
# 1. 修改 hooks.php
vi /path/to/whmcs/modules/addons/domain_hub/hooks.php

# 2. 在后台配置界面设置测试值
# 例如：设置同步间隔为 5000 分钟

# 3. 手动触发 WHMCS cron
php /path/to/whmcs/crons/cron.php

# 4. 检查任务表
mysql -u用户名 -p数据库名 -e "
SELECT id, type, created_at, updated_at, 
TIMESTAMPDIFF(MINUTE, created_at, updated_at) as interval_minutes
FROM mod_cloudflare_jobs 
WHERE type = 'calibrate_all' 
ORDER BY id DESC LIMIT 5;"
```

### 2. 验证配置是否生效

```php
// 在 hooks.php 第36行后添加调试代码（测试完记得删除）
error_log('[DomainHub] Sync interval set to: ' . $intervalMin . ' minutes');
```

查看日志：
```bash
tail -f /var/log/php-fpm/error.log | grep DomainHub
```

---

## 📋 完整修改清单

### 文件：hooks.php

```php
// ============================================
// 第36行：自动同步间隔上限
// ============================================
// 改为 7天
$intervalMin = max(5, min(10080, $intervalMin));

// ============================================
// 第71行：风险扫描间隔上限
// ============================================
// 改为 7天
$scanIntervalMin = max(15, min(10080, $scanIntervalMin));

// ============================================
// 第290-296行：域名清理间隔上限
// ============================================
// 改为 30天
if ($cleanupIntervalHours < 1) {
    $cleanupIntervalHours = 1;
} elseif ($cleanupIntervalHours > 720) {
    $cleanupIntervalHours = 720;
}
```

---

## 🎯 推荐配置

### 场景1：标准配置（不修改代码）

```
同步间隔：60-120 分钟
风险扫描：120-240 分钟
域名清理：24 小时
```

### 场景2：低频变更（修改上限为7天）

```
同步间隔：720-1440 分钟（12-24小时）
风险扫描：1440-2880 分钟（24-48小时）
域名清理：48-72 小时
```

### 场景3：超大型部署（修改上限为30天）

```
同步间隔：4320-10080 分钟（3-7天）
风险扫描：10080-20160 分钟（7-14天）
域名清理：168-360 小时（7-15天）
```

---

## ⚠️ 特殊情况处理

### 情况1：改为999999会怎样？

**不会报错，但会出现问题：**

```php
$intervalMin = max(5, min(999999, $intervalMin));

// 用户设置 5000 分钟
// 实际使用：5000 分钟 ✅

// 用户设置 999999 分钟  
// 实际使用：999999 分钟 = 694天 ⚠️

// 问题：
// 1. 任务694天才执行一次，基本等于不执行
// 2. MySQL 时间计算可能溢出
// 3. WHMCS cron 可能出现异常
```

**建议：改为合理值，如 43200（30天）已经是极限**

### 情况2：完全去掉限制？

```php
// ❌ 不推荐：完全去掉上限
$intervalMin = max(5, $intervalMin);

// 问题：
// 1. 用户可能误输入超大值
// 2. 没有保护机制
// 3. 可能导致任务永远不执行
```

**建议：至少保留一个合理的上限（如30天）**

---

## 🔄 回滚方案

如果修改后出现问题，立即回滚：

```bash
# 1. 恢复原始代码
cd /path/to/whmcs/modules/addons/domain_hub/
git checkout hooks.php

# 或手动改回
vi hooks.php
# 第36行改回：$intervalMin = max(5, min(1440, $intervalMin));

# 2. 重置配置为默认值
mysql -u用户名 -p数据库名 -e "
UPDATE tbladdonmodules 
SET value = '60' 
WHERE module = 'domain_hub' 
AND setting = 'sync_interval';"

# 3. 清空异常任务
mysql -u用户名 -p数据库名 -e "
DELETE FROM mod_cloudflare_jobs 
WHERE status = 'pending' 
AND created_at < DATE_SUB(NOW(), INTERVAL 2 DAY);"
```

---

## ✅ 修改检查清单

修改前：
- [ ] 备份 hooks.php 文件
- [ ] 记录当前配置值
- [ ] 确定合理的新上限值

修改后：
- [ ] 语法检查（`php -l hooks.php`）
- [ ] 在后台配置界面测试设置新值
- [ ] 检查任务队列是否正常创建
- [ ] 观察服务器日志是否有错误
- [ ] 验证实际间隔是否符合预期

生产环境：
- [ ] 在测试环境验证无误后再部署
- [ ] 逐步增加间隔值，观察影响
- [ ] 监控任务执行情况至少一周

---

## 📞 常见问题

**Q: 修改后需要重启服务吗？**  
A: 不需要，WHMCS cron 下次运行时会自动加载新代码。

**Q: 已经设置的超过1440的值会自动调整吗？**  
A: 修改代码后，下次执行时会按新上限生效。

**Q: 能设置不同的表达式吗（如2天 + 3小时）？**  
A: 可以，修改为：`max(5, min(2*1440 + 180, $intervalMin))` = 3060分钟

**Q: 修改后会影响已有任务吗？**  
A: 不会，只影响新创建的任务的间隔计算。

---

**更新时间**: 2025-01-XX  
**适用版本**: v2.x+
