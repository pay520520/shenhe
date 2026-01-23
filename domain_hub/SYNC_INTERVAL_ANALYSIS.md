# 自动同步间隔配置分析报告

## 📋 配置概览

### 1. 自动同步（Calibrate/Sync）间隔

**配置项**: `sync_interval`  
**位置**: `domain_hub.php` 第1329-1335行

```php
"sync_interval" => [
    "FriendlyName" => "同步间隔（分钟）",
    "Type" => "text",
    "Size" => "5",
    "Default" => "60",
    "Description" => "与阿里云DNS同步的间隔时间（分钟）",
],
```

#### ⚠️ 重要发现

**配置文件中**:
- ✅ **不是写死固定的**
- ✅ 可以在 WHMCS 后台配置界面修改
- ✅ 默认值: **60分钟**
- ✅ 输入框大小: 5个字符（可输入最多99999分钟）

**代码验证逻辑** (`hooks.php` 第35-36行):
```php
$intervalMin = intval($settings['sync_interval'] ?? 60);
$intervalMin = max(5, min(1440, $intervalMin));
```

#### ✅ 实际限制

| 项目 | 值 | 说明 |
|------|-----|------|
| **最小值** | **5分钟** | 硬编码限制，小于5分钟会被强制调整为5分钟 |
| **最大值** | **1440分钟** (24小时) | 硬编码限制，大于1440分钟会被强制调整为1440分钟 |
| **默认值** | 60分钟 (1小时) | 首次激活插件的默认值 |
| **建议值** | 30-120分钟 | 平衡性能与实时性 |

---

## 🔄 其他自动任务间隔配置

### 2. 风险扫描间隔

**配置项**: `risk_scan_interval`  
**位置**: `domain_hub.php` 第1538-1544行

```php
"risk_scan_interval" => [
    "FriendlyName" => "风险扫描间隔（分钟）",
    "Type" => "text",
    "Size" => "5",
    "Default" => "120",
    "Description" => "建议 ≥ 60 分钟",
],
```

**代码验证逻辑** (`hooks.php` 第70-71行):
```php
$scanIntervalMin = intval($settings['risk_scan_interval'] ?? 120);
$scanIntervalMin = max(15, min(1440, $scanIntervalMin));
```

| 项目 | 值 | 说明 |
|------|-----|------|
| **最小值** | **15分钟** | 防止频繁调用外部API |
| **最大值** | **1440分钟** (24小时) | 与同步间隔一致 |
| **默认值** | 120分钟 (2小时) | |
| **建议值** | ≥ 60分钟 | 配置说明中明确建议 |

### 3. 域名清理间隔

**配置项**: `domain_cleanup_interval_hours`  
**位置**: `domain_hub.php` (未在代码段中，但在hooks.php中引用)

**代码验证逻辑** (`hooks.php` 第290-296行):
```php
$cleanupIntervalHoursRaw = $settings['domain_cleanup_interval_hours'] ?? 24;
$cleanupIntervalHours = is_numeric($cleanupIntervalHoursRaw) ? (int) $cleanupIntervalHoursRaw : 24;
if ($cleanupIntervalHours < 1) {
    $cleanupIntervalHours = 1;
} elseif ($cleanupIntervalHours > 168) {
    $cleanupIntervalHours = 168;
}
```

| 项目 | 值 | 说明 |
|------|-----|------|
| **最小值** | **1小时** | |
| **最大值** | **168小时** (7天) | |
| **默认值** | 24小时 (1天) | |

---

## 📊 配置灵活性总结

### ✅ 优点

1. **可配置性强**: 所有间隔都可以通过后台配置界面修改
2. **有合理限制**: 设置了最小值和最大值，防止配置不当
3. **默认值合理**: 开箱即用，无需手动调整
4. **输入框友好**: 文本框大小适中，允许输入较大数值

### ⚠️ 需要注意的点

1. **自动同步最小间隔**: 5分钟
   - 过于频繁可能增加数据库和DNS服务器负载
   - 建议生产环境至少设置30分钟以上

2. **自动同步最大间隔**: 1440分钟 (24小时)
   - 如果需要更长间隔，需要修改代码
   - 位置: `hooks.php` 第36行

3. **风险扫描最小间隔**: 15分钟
   - 过于频繁可能触发外部API限速
   - 建议≥60分钟

---

## 🔧 如何修改间隔限制

### 修改自动同步最大值

**文件**: `domain_hub/hooks.php`  
**行号**: 第36行

```php
// 修改前
$intervalMin = max(5, min(1440, $intervalMin));

// 修改后（例如改为最大7天 = 10080分钟）
$intervalMin = max(5, min(10080, $intervalMin));
```

### 修改风险扫描最大值

**文件**: `domain_hub/hooks.php`  
**行号**: 第71行

```php
// 修改前
$scanIntervalMin = max(15, min(1440, $scanIntervalMin));

// 修改后（例如改为最大7天 = 10080分钟）
$scanIntervalMin = max(15, min(10080, $scanIntervalMin));
```

---

## 📈 性能建议

### 根据规模推荐的间隔设置

| 规模 | 域名数 | 同步间隔 | 风险扫描 | 清理间隔 |
|------|--------|----------|----------|----------|
| 小型 | < 1000 | 30-60分钟 | 120分钟 | 24小时 |
| 中型 | 1000-5000 | 60-120分钟 | 180分钟 | 24小时 |
| 大型 | 5000-20000 | 120-240分钟 | 240分钟 | 24小时 |
| 超大型 | > 20000 | 240-720分钟 | 360分钟 | 24-48小时 |

### 考虑因素

1. **DNS记录变更频率**
   - 频繁变更: 缩短同步间隔
   - 稳定运行: 延长同步间隔

2. **服务器性能**
   - CPU/内存充足: 可缩短间隔
   - 资源紧张: 延长间隔，避免任务堆积

3. **外部API限制**
   - 风险扫描依赖外部API，避免过于频繁调用

4. **用户体验要求**
   - 高实时性要求: 缩短同步间隔
   - 常规使用: 默认值即可

---

## 🎯 最佳实践

### 1. 初始配置（推荐）

```
同步间隔: 60分钟
风险扫描: 120分钟
域名清理: 24小时
校准批量: 150条/次
```

### 2. 高负载优化

```
同步间隔: 120-240分钟
风险扫描: 240-360分钟
域名清理: 24-48小时
校准批量: 100条/次（减少单次负载）
```

### 3. 实时性优化

```
同步间隔: 15-30分钟
风险扫描: 60-120分钟
域名清理: 12-24小时
校准批量: 200-300条/次
```

---

## ⚙️ 配置位置

### WHMCS后台配置路径

1. 登录 WHMCS 管理后台
2. 进入: **设置 → 附加组件**
3. 找到: **阿里云DNS 域名分发** 插件
4. 点击: **配置**
5. 找到对应配置项进行修改

### 配置项列表

| 配置项 | 友好名称 | 位置 |
|--------|----------|------|
| `enable_auto_sync` | 启用自动同步 | 自动同步部分 |
| `sync_interval` | 同步间隔（分钟） | 自动同步部分 |
| `risk_scan_enabled` | 启用周期性风险扫描 | 风险监控部分 |
| `risk_scan_interval` | 风险扫描间隔（分钟） | 风险监控部分 |
| `domain_cleanup_interval_hours` | 自动清理检查间隔 | 域名清理部分 |

---

## 🔍 验证配置是否生效

### 1. 检查配置值

```sql
-- 查询当前配置
SELECT setting, value 
FROM tbladdonmodules 
WHERE module = 'domain_hub' 
AND setting IN ('sync_interval', 'risk_scan_interval', 'enable_auto_sync', 'domain_cleanup_interval_hours')
ORDER BY setting;
```

### 2. 检查任务执行情况

```sql
-- 查看最近的同步任务
SELECT id, type, status, created_at, updated_at, attempts
FROM mod_cloudflare_jobs
WHERE type = 'calibrate_all'
ORDER BY id DESC
LIMIT 10;

-- 查看最近的风险扫描任务
SELECT id, type, status, created_at, updated_at, attempts
FROM mod_cloudflare_jobs
WHERE type = 'risk_scan_all'
ORDER BY id DESC
LIMIT 10;
```

### 3. 计算实际间隔

```sql
-- 计算实际同步间隔（最近5次）
SELECT 
    type,
    created_at,
    LAG(created_at) OVER (ORDER BY created_at DESC) as prev_created,
    TIMESTAMPDIFF(MINUTE, created_at, LAG(created_at) OVER (ORDER BY created_at DESC)) as interval_minutes
FROM mod_cloudflare_jobs
WHERE type = 'calibrate_all' AND status IN ('done', 'failed')
ORDER BY created_at DESC
LIMIT 5;
```

---

## ✅ 结论

### 回答原始问题

**Q: 同步间隔（分钟）是写死固定的吗？**  
**A**: ❌ **不是固定的**，可以在后台配置界面自由修改。

**Q: 最高可以设置多少分钟？**  
**A**: ✅ **最高1440分钟（24小时）**，这是代码中硬编码的上限。

### 代码位置总结

| 配置定义 | 代码验证 | 作用 |
|----------|----------|------|
| `domain_hub.php` 第1329-1335行 | `hooks.php` 第35-36行 | 自动同步间隔 |
| `domain_hub.php` 第1538-1544行 | `hooks.php` 第70-71行 | 风险扫描间隔 |
| 配置文件中 | `hooks.php` 第290-296行 | 域名清理间隔 |

### 修改建议

1. ✅ **默认配置已经很合理**，无需修改即可投入生产使用
2. ⚠️ **最小值不建议低于30分钟**（尽管代码允许5分钟）
3. ✅ **如需更长间隔**，可修改 `hooks.php` 中的 `min()` 上限值
4. 📊 **建议根据实际负载监控调整**，而非盲目追求最短间隔

---

**生成时间**: 2025-01-XX  
**插件版本**: v2.x  
**文档版本**: 1.0
