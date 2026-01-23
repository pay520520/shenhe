# 根域名排序功能完整指南

## 📊 数据库表结构

### 主表：`mod_cloudflare_rootdomains`

**表名**: `mod_cloudflare_rootdomains`

**排序相关字段**:
- `id` - 主键ID（自增）
- `display_order` - 显示排序（整数，默认0）
- `domain` - 域名（字符串）
- `status` - 状态（active/inactive）
- `created_at` - 创建时间
- `updated_at` - 更新时间

### 完整表结构

```sql
CREATE TABLE `mod_cloudflare_rootdomains` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `domain` varchar(255) NOT NULL,
  `provider_account_id` int(10) unsigned DEFAULT NULL,
  `cloudflare_zone_id` varchar(50) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'active',
  `maintenance` tinyint(1) DEFAULT 0,
  `display_order` int(11) DEFAULT 0,              -- 👈 排序字段
  `description` text DEFAULT NULL,
  `max_subdomains` int(11) DEFAULT 1000,
  `per_user_limit` int(11) DEFAULT 0,
  `default_term_years` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mod_cloudflare_rootdomains_domain_unique` (`domain`),
  KEY `mod_cloudflare_rootdomains_status_index` (`status`),
  KEY `mod_cloudflare_rootdomains_provider_account_id_index` (`provider_account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 🔍 排序机制详解

### 1. 后台显示排序逻辑

**代码位置**: `lib/Services/AdminViewModelBuilder.php` 第195-198行

```php
$result['rootdomains'] = Capsule::table('mod_cloudflare_rootdomains')
    ->orderBy('display_order', 'asc')  // 👈 第一优先级：按display_order升序
    ->orderBy('id', 'asc')              // 👈 第二优先级：按id升序
    ->get();
```

**排序规则**:
1. **第一优先级**: `display_order` 升序（从小到大）
2. **第二优先级**: `id` 升序（当 display_order 相同时）

### 2. 前端显示排序逻辑

**代码位置**: `lib/Services/ClientViewModelBuilder.php`

```php
$roots = Capsule::table('mod_cloudflare_rootdomains')
    ->where('status', 'active')
    ->orderBy('display_order', 'asc')  // 👈 按display_order排序
    ->orderBy('id', 'asc')
    ->pluck('domain')
    ->toArray();
```

**说明**: 前端用户看到的根域名列表也是按 `display_order` 排序的。

---

## 🎯 手动修改排序

### 方法1：直接修改数据库（推荐用于批量调整）

#### SQL示例1：设置单个域名的排序

```sql
-- 将 example.com 的排序设置为 10
UPDATE mod_cloudflare_rootdomains 
SET display_order = 10, 
    updated_at = NOW() 
WHERE domain = 'example.com';
```

#### SQL示例2：批量设置排序

```sql
-- 设置多个域名的排序
UPDATE mod_cloudflare_rootdomains SET display_order = 10, updated_at = NOW() WHERE domain = 'aaa.com';
UPDATE mod_cloudflare_rootdomains SET display_order = 20, updated_at = NOW() WHERE domain = 'bbb.com';
UPDATE mod_cloudflare_rootdomains SET display_order = 30, updated_at = NOW() WHERE domain = 'ccc.com';
UPDATE mod_cloudflare_rootdomains SET display_order = 40, updated_at = NOW() WHERE domain = 'ddd.com';
```

#### SQL示例3：根据ID批量设置

```sql
-- 按ID批量设置
UPDATE mod_cloudflare_rootdomains SET display_order = 100, updated_at = NOW() WHERE id = 1;
UPDATE mod_cloudflare_rootdomains SET display_order = 200, updated_at = NOW() WHERE id = 2;
UPDATE mod_cloudflare_rootdomains SET display_order = 300, updated_at = NOW() WHERE id = 3;
```

#### SQL示例4：使用 CASE 语句批量更新

```sql
-- 一次SQL更新多个
UPDATE mod_cloudflare_rootdomains 
SET 
    display_order = CASE 
        WHEN domain = 'aaa.com' THEN 10
        WHEN domain = 'bbb.com' THEN 20
        WHEN domain = 'ccc.com' THEN 30
        WHEN domain = 'ddd.com' THEN 40
        ELSE display_order
    END,
    updated_at = NOW()
WHERE domain IN ('aaa.com', 'bbb.com', 'ccc.com', 'ddd.com');
```

#### SQL示例5：重置所有排序为ID值

```sql
-- 将所有域名的排序重置为其ID值
UPDATE mod_cloudflare_rootdomains 
SET display_order = id, 
    updated_at = NOW();
```

#### SQL示例6：按域名字母顺序重新编号

```sql
-- 先查看当前顺序
SELECT @row_number := 0;
SELECT 
    (@row_number := @row_number + 10) AS new_order,
    id,
    domain,
    display_order as old_order
FROM mod_cloudflare_rootdomains
ORDER BY domain ASC;

-- 实际更新（按字母顺序重新编号，间隔10）
SET @row_number := 0;
UPDATE mod_cloudflare_rootdomains
SET display_order = (@row_number := @row_number + 10),
    updated_at = NOW()
ORDER BY domain ASC;
```

---

### 方法2：通过后台界面修改

**步骤**：
1. 登录 WHMCS 管理后台
2. 进入：**附加组件 → 阿里云DNS 域名分发**
3. 找到：**根域名白名单管理** 部分
4. 点击：**排序** 按钮或输入框
5. 输入新的排序数字
6. 点击：**保存排序** 按钮

**后台处理逻辑** (`lib/Services/AdminActionService.php` 第588-635行):

```php
private static function handleRootdomainOrderUpdate(): void
{
    $orders = $_POST['display_order'] ?? [];
    
    // 验证和清理数据
    $sanitized = [];
    foreach ($orders as $id => $value) {
        $orderValue = is_numeric($value) ? (int) $value : 0;
        
        // 限制范围：-1000000 到 1000000
        if ($orderValue < -1000000) {
            $orderValue = -1000000;
        } elseif ($orderValue > 1000000) {
            $orderValue = 1000000;
        }
        
        $sanitized[(int) $id] = $orderValue;
    }
    
    // 更新数据库
    foreach ($existingIds as $id) {
        $orderValue = $sanitized[(int) $id] ?? 0;
        Capsule::table('mod_cloudflare_rootdomains')
            ->where('id', $id)
            ->update([
                'display_order' => $orderValue,
                'updated_at' => $now,
            ]);
    }
}
```

---

## 📋 排序值规则

### 有效范围

| 项目 | 值 | 说明 |
|------|-----|------|
| **最小值** | -1000000 | 代码硬限制 |
| **最大值** | 1000000 | 代码硬限制 |
| **默认值** | 0 | 新增根域名时的默认值 |
| **推荐间隔** | 10 | 便于插入新项 |

### 排序原理

```
display_order: -100  →  显示在最前面
display_order: 0     →  默认位置
display_order: 10    →  
display_order: 20    →  
display_order: 100   →  显示在最后面
```

**注意**: 
- 值越小，显示越靠前
- 相同值按 `id` 排序

---

## 🔧 常见场景示例

### 场景1：置顶某个域名

```sql
-- 将 vip.com 置顶（设置为负数或很小的值）
UPDATE mod_cloudflare_rootdomains 
SET display_order = -100, 
    updated_at = NOW() 
WHERE domain = 'vip.com';
```

**效果**: `vip.com` 会显示在最前面

---

### 场景2：将某个域名放到最后

```sql
-- 将 test.com 放到最后（设置为很大的值）
UPDATE mod_cloudflare_rootdomains 
SET display_order = 999999, 
    updated_at = NOW() 
WHERE domain = 'test.com';
```

**效果**: `test.com` 会显示在最后

---

### 场景3：按字母顺序排列

```sql
-- 按域名字母顺序重新排序（间隔10）
SET @row_number := 0;
UPDATE mod_cloudflare_rootdomains
SET display_order = (@row_number := @row_number + 10),
    updated_at = NOW()
ORDER BY domain ASC;
```

---

### 场景4：按ID顺序排列

```sql
-- 按ID顺序重新排序
UPDATE mod_cloudflare_rootdomains 
SET display_order = id, 
    updated_at = NOW();
```

---

### 场景5：按创建时间排序

```sql
-- 按创建时间重新排序（最新的在前，间隔10）
SET @row_number := 0;
UPDATE mod_cloudflare_rootdomains
SET display_order = (@row_number := @row_number + 10),
    updated_at = NOW()
ORDER BY created_at DESC;
```

---

### 场景6：自定义排序组

```sql
-- VIP域名：排序 0-99
UPDATE mod_cloudflare_rootdomains SET display_order = 10, updated_at = NOW() WHERE domain = 'premium1.com';
UPDATE mod_cloudflare_rootdomains SET display_order = 20, updated_at = NOW() WHERE domain = 'premium2.com';

-- 普通域名：排序 100-999
UPDATE mod_cloudflare_rootdomains SET display_order = 100, updated_at = NOW() WHERE domain = 'normal1.com';
UPDATE mod_cloudflare_rootdomains SET display_order = 200, updated_at = NOW() WHERE domain = 'normal2.com';

-- 测试域名：排序 1000+
UPDATE mod_cloudflare_rootdomains SET display_order = 1000, updated_at = NOW() WHERE domain = 'test1.com';
UPDATE mod_cloudflare_rootdomains SET display_order = 2000, updated_at = NOW() WHERE domain = 'test2.com';
```

---

## 📊 查看当前排序

### SQL查询当前排序状态

```sql
-- 查看所有根域名及其排序
SELECT 
    id,
    domain,
    display_order,
    status,
    created_at
FROM mod_cloudflare_rootdomains
ORDER BY display_order ASC, id ASC;
```

### 查看排序统计

```sql
-- 统计排序分布
SELECT 
    CASE 
        WHEN display_order < 0 THEN '负数（置顶）'
        WHEN display_order = 0 THEN '默认（0）'
        WHEN display_order > 0 AND display_order < 100 THEN '1-99'
        WHEN display_order >= 100 AND display_order < 1000 THEN '100-999'
        ELSE '1000+'
    END AS range_group,
    COUNT(*) as count
FROM mod_cloudflare_rootdomains
GROUP BY range_group
ORDER BY MIN(display_order);
```

### 查找排序冲突

```sql
-- 查找相同排序值的域名
SELECT 
    display_order,
    GROUP_CONCAT(domain ORDER BY id SEPARATOR ', ') as domains,
    COUNT(*) as count
FROM mod_cloudflare_rootdomains
GROUP BY display_order
HAVING count > 1
ORDER BY display_order;
```

---

## ⚠️ 注意事项

### 1. 排序值范围限制

- ✅ **允许**: -1000000 到 1000000
- ❌ **超出范围**: 会被自动调整到边界值

```php
// 代码限制（AdminActionService.php 第601-605行）
if ($orderValue < -1000000) {
    $orderValue = -1000000;
} elseif ($orderValue > 1000000) {
    $orderValue = 1000000;
}
```

### 2. 更新时间

手动修改数据库时，建议同时更新 `updated_at` 字段：

```sql
UPDATE mod_cloudflare_rootdomains 
SET display_order = 10, 
    updated_at = NOW()  -- 👈 重要！
WHERE domain = 'example.com';
```

### 3. 排序冲突

- 多个域名可以有相同的 `display_order`
- 相同值时按 `id` 排序
- 建议使用间隔值（如10, 20, 30）便于插入

### 4. 缓存问题

某些部署可能有缓存，修改后需要：
- 清除 WHMCS 缓存
- 刷新浏览器页面
- 重新登录后台

---

## 🔄 批量操作工具

### 生成排序SQL的PHP脚本

```php
<?php
// generate_sort_sql.php
// 用于生成批量更新排序的SQL语句

$domains = [
    'aaa.com' => 10,
    'bbb.com' => 20,
    'ccc.com' => 30,
    'ddd.com' => 40,
];

foreach ($domains as $domain => $order) {
    echo "UPDATE mod_cloudflare_rootdomains ";
    echo "SET display_order = {$order}, updated_at = NOW() ";
    echo "WHERE domain = '{$domain}';\n";
}
?>
```

运行：
```bash
php generate_sort_sql.php > sort_updates.sql
mysql -u用户名 -p数据库名 < sort_updates.sql
```

---

## 🐛 故障排查

### 问题1：排序不生效

**检查步骤**：

1. 验证数据库已更新：
```sql
SELECT id, domain, display_order 
FROM mod_cloudflare_rootdomains 
WHERE domain = 'example.com';
```

2. 检查是否有字段：
```sql
SHOW COLUMNS FROM mod_cloudflare_rootdomains LIKE 'display_order';
```

3. 清除缓存重试

---

### 问题2：排序字段不存在

**解决方案**：

```sql
-- 检查字段是否存在
SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'mod_cloudflare_rootdomains' 
AND COLUMN_NAME = 'display_order';

-- 如果不存在，手动添加
ALTER TABLE mod_cloudflare_rootdomains 
ADD COLUMN display_order INT DEFAULT 0 AFTER status;

-- 初始化排序值为ID
UPDATE mod_cloudflare_rootdomains 
SET display_order = id 
WHERE display_order IS NULL OR display_order = 0;
```

---

### 问题3：前端显示顺序不对

**可能原因**：
1. 浏览器缓存
2. WHMCS 缓存
3. 多个域名排序值相同

**解决方案**：
```sql
-- 查看实际排序
SELECT id, domain, display_order 
FROM mod_cloudflare_rootdomains 
ORDER BY display_order ASC, id ASC;

-- 重新设置唯一排序值
SET @row_number := 0;
UPDATE mod_cloudflare_rootdomains
SET display_order = (@row_number := @row_number + 10)
ORDER BY display_order ASC, id ASC;
```

---

## ✅ 快速参考

### 常用SQL命令

```sql
-- 1. 查看所有排序
SELECT id, domain, display_order FROM mod_cloudflare_rootdomains ORDER BY display_order, id;

-- 2. 置顶域名
UPDATE mod_cloudflare_rootdomains SET display_order = -100, updated_at = NOW() WHERE domain = 'vip.com';

-- 3. 置底域名
UPDATE mod_cloudflare_rootdomains SET display_order = 999999, updated_at = NOW() WHERE domain = 'test.com';

-- 4. 重置为ID顺序
UPDATE mod_cloudflare_rootdomains SET display_order = id, updated_at = NOW();

-- 5. 按字母排序
SET @row_number := 0;
UPDATE mod_cloudflare_rootdomains SET display_order = (@row_number := @row_number + 10), updated_at = NOW() ORDER BY domain;
```

---

**创建时间**: 2025-01-XX  
**文档版本**: 1.0  
**适用插件版本**: v2.x+
