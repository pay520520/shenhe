# 根域名邀请表单警告提示优化

## 修改时间
2025-01-XX

## 修改内容

### 1. 模板文件修改
**文件**: `templates/client/partials/modals.tpl`

#### 修改位置: 第803-820行
- **原有样式**: `alert-info` (蓝色信息提示框)
- **新样式**: `alert-warning` (黄色警告提示框)
- **背景色**: `#fff3cd` (浅黄色)
- **边框色**: `#ffc107` (黄色)

#### 新增内容:
1. **重要提醒标题**:
   - 图标: `fas fa-exclamation-triangle` (警告三角图标)
   - 文字: "重要提醒："

2. **警告文字**:
   - 中文: "您可以分享给好友注册码，但请提醒对方遵守域名使用规则。一旦对方违规使用，您的账户也会同步被封禁。"
   - 英文: "You may share your invite code with friends, but please remind them to comply with domain usage rules. If they violate the rules, your account will also be banned."

3. **视觉效果**:
   - 使用 `border-top` 分隔线将警告与描述文字分开
   - 分隔线颜色与边框一致 (`#ffc107`)
   - 使用 flexbox 布局，图标和文字对齐

### 2. 语言文件修改

#### 中文语言包 (`lang/chinese.php`)
新增翻译键值:
```php
$_LANG['cfclient.rootdomain_invite.important_reminder'] = '重要提醒：';
$_LANG['cfclient.rootdomain_invite.important_warning'] = '您可以分享给好友注册码，但请提醒对方遵守域名使用规则。一旦对方违规使用，您的账户也会同步被封禁。';
$_LANG['cfclient.rootdomain_invite.limit_reached_title'] = '已达邀请上限';
$_LANG['cfclient.rootdomain_invite.limit_reached_desc'] = '您已邀请 %s 人，已达到该根域名的邀请上限（最多 %s 人）。';
```

#### 英文语言包 (`lang/english.php`)
新增翻译键值:
```php
$_LANG['cfclient.rootdomain_invite.important_reminder'] = 'Important Notice:';
$_LANG['cfclient.rootdomain_invite.important_warning'] = 'You may share your invite code with friends, but please remind them to comply with domain usage rules. If they violate the rules, your account will also be banned.';
$_LANG['cfclient.rootdomain_invite.limit_reached_title'] = 'Invitation Limit Reached';
$_LANG['cfclient.rootdomain_invite.limit_reached_desc'] = 'You have invited %s users, reaching the maximum limit of %s invitations for this root domain.';
```

## 修改目的
1. **增强警示效果**: 使用黄色警告色替代蓝色信息色，更能引起用户注意
2. **明确责任**: 清晰告知用户，分享邀请码需要承担连带责任
3. **防止滥用**: 通过醒目的警告，降低用户随意分享邀请码的可能性
4. **符合用户要求**: 与邀请注册功能的黄色背景提示保持一致

## 效果预览

### 修改前
```
[蓝色信息框]
ℹ️ 以下根域名需要邀请码才能注册。您可以分享您的邀请码给好友，好友使用后邀请码会自动刷新。
```

### 修改后
```
[黄色警告框]
ℹ️ 以下根域名需要邀请码才能注册。您可以分享您的邀请码给好友，好友使用后邀请码会自动刷新。
─────────────────────────────────────────
⚠️ 重要提醒：您可以分享给好友注册码，但请提醒对方遵守域名使用规则。一旦对方违规使用，您的账户也会同步被封禁。
```

## 技术细节

### HTML 结构
```html
<div class="alert alert-warning" style="background-color: #fff3cd; border-color: #ffc107;">
    <div class="d-flex align-items-start">
        <i class="fas fa-info-circle me-2 mt-1"></i>
        <div class="flex-grow-1">
            <div class="mb-2">
                <!-- 原有描述文字 -->
            </div>
            <div class="border-top pt-2" style="border-color: #ffc107 !important;">
                <strong><i class="fas fa-exclamation-triangle me-1"></i>重要提醒：</strong>
                <!-- 警告文字 -->
            </div>
        </div>
    </div>
</div>
```

### CSS 说明
- `alert-warning`: Bootstrap 警告样式类
- `background-color: #fff3cd`: 浅黄色背景（与邀请注册一致）
- `border-color: #ffc107`: 黄色边框
- `d-flex align-items-start`: Flexbox 布局，顶部对齐
- `border-top pt-2`: 上边框分隔线，顶部padding
- `fas fa-exclamation-triangle`: Font Awesome 警告图标

## 兼容性
- ✅ Bootstrap 5.x
- ✅ Font Awesome 5.x/6.x
- ✅ 响应式设计（移动端友好）
- ✅ 多语言支持（中文/英文）

## 测试建议
1. 检查在不同语言下显示是否正确
2. 验证黄色背景是否与其他警告提示一致
3. 测试移动端显示效果
4. 确认图标和文字对齐
5. 检查分隔线颜色是否正确

## 相关文件
- `templates/client/partials/modals.tpl` (第803-820行)
- `lang/chinese.php` (第244-253行)
- `lang/english.php` (第245-254行)
