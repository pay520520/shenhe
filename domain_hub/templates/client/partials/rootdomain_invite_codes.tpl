<?php
// 根域名邀请码显示
$rootdomainInviteCodes = $rootdomainInviteCodes ?? [];
$rootInviteRequiredMap = $rootInviteRequiredMap ?? [];
$rootdomainInviteMaxPerUser = $rootdomainInviteMaxPerUser ?? 0;

// 过滤出需要邀请码的根域名
$inviteEnabledRoots = [];
foreach ($rootInviteRequiredMap as $root => $required) {
    if ($required) {
        $inviteEnabledRoots[] = $root;
    }
}

// 如果没有启用邀请码的根域名，不显示此卡片
if (empty($inviteEnabledRoots)) {
    return;
}

$inviteText = static function (string $key, string $default, array $params = [], bool $escape = true): string {
    return cfclient_lang($key, $default, $params, $escape);
};
?>

<!-- 根域名邀请码 -->
<div class="card mb-4 border-0 shadow-sm">
    <div class="card-body">
        <div class="d-flex align-items-center mb-3">
            <h5 class="card-title mb-0">
                <i class="fas fa-gift text-primary"></i> <?php echo $inviteText('cfclient.rootdomain_invite.title', '根域名邀请码', [], true); ?>
            </h5>
        </div>
        
        <div class="alert alert-info">
            <i class="fas fa-info-circle"></i>
            <?php if ($rootdomainInviteMaxPerUser > 0): ?>
                <?php echo $inviteText('cfclient.rootdomain_invite.description_with_limit', '以下根域名需要邀请码才能注册。您可以分享您的邀请码给好友，每个根域名最多可邀请 %s 个好友。邀请码使用后会自动刷新。', [$rootdomainInviteMaxPerUser], true); ?>
            <?php else: ?>
                <?php echo $inviteText('cfclient.rootdomain_invite.description', '以下根域名需要邀请码才能注册。您可以分享您的邀请码给好友，好友使用后邀请码会自动刷新。', [], true); ?>
            <?php endif; ?>
        </div>

        <div class="row g-3">
            <?php foreach ($inviteEnabledRoots as $rootdomain): ?>
                <?php
                $inviteCodeData = $rootdomainInviteCodes[$rootdomain] ?? null;
                $inviteCode = $inviteCodeData ? ($inviteCodeData['invite_code'] ?? '') : '';
                
                // 如果用户还没有这个根域名的邀请码，自动生成
                if ($inviteCode === '' && ($userid ?? 0) > 0) {
                    try {
                        if (class_exists('CfRootdomainInviteService')) {
                            $generated = CfRootdomainInviteService::getOrCreateInviteCode($userid, $rootdomain);
                            $inviteCode = $generated['invite_code'] ?? '';
                        }
                    } catch (\Throwable $e) {
                        $inviteCode = '';
                    }
                }
                
                // 获取该根域名已邀请人数
                $invitedCount = 0;
                try {
                    if (class_exists('CfRootdomainInviteService') && ($userid ?? 0) > 0) {
                        $invitedCount = CfRootdomainInviteService::getUserInviteCount($userid, $rootdomain);
                    }
                } catch (\Throwable $e) {
                    $invitedCount = 0;
                }
                
                $remainingInvites = $rootdomainInviteMaxPerUser > 0 ? max(0, $rootdomainInviteMaxPerUser - $invitedCount) : -1;
                ?>
                <div class="col-md-6 col-lg-4">
                    <div class="card h-100">
                        <div class="card-body">
                            <h6 class="card-title">
                                <i class="fas fa-server text-success"></i>
                                <code><?php echo htmlspecialchars($rootdomain); ?></code>
                            </h6>
                            
                            <?php if ($inviteCode !== ''): ?>
                                <div class="mb-3">
                                    <label class="form-label small text-muted">
                                        <?php echo $inviteText('cfclient.rootdomain_invite.your_code', '您的邀请码', [], true); ?>
                                    </label>
                                    <div class="input-group">
                                        <input type="text" class="form-control form-control-sm font-monospace" 
                                               value="<?php echo htmlspecialchars($inviteCode); ?>" 
                                               id="invite_code_<?php echo htmlspecialchars($rootdomain); ?>" 
                                               readonly>
                                        <button class="btn btn-sm btn-outline-primary" type="button" 
                                                onclick="copyInviteCode('<?php echo htmlspecialchars($rootdomain, ENT_QUOTES); ?>')">
                                            <i class="fas fa-copy"></i>
                                        </button>
                                    </div>
                                </div>
                                
                                <div class="d-flex justify-content-between align-items-center">
                                    <small class="text-muted">
                                        <i class="fas fa-users"></i>
                                        <?php echo $inviteText('cfclient.rootdomain_invite.invited_count', '已邀请：%s 人', [$invitedCount], true); ?>
                                    </small>
                                    <?php if ($remainingInvites >= 0): ?>
                                        <small class="<?php echo $remainingInvites > 0 ? 'text-success' : 'text-danger'; ?>">
                                            <?php if ($remainingInvites > 0): ?>
                                                <i class="fas fa-check-circle"></i>
                                                <?php echo $inviteText('cfclient.rootdomain_invite.remaining', '剩余：%s', [$remainingInvites], true); ?>
                                            <?php else: ?>
                                                <i class="fas fa-exclamation-triangle"></i>
                                                <?php echo $inviteText('cfclient.rootdomain_invite.limit_reached', '已达上限', [], true); ?>
                                            <?php endif; ?>
                                        </small>
                                    <?php endif; ?>
                                </div>
                            <?php else: ?>
                                <div class="alert alert-warning mb-0">
                                    <small>
                                        <i class="fas fa-exclamation-triangle"></i>
                                        <?php echo $inviteText('cfclient.rootdomain_invite.code_not_generated', '邀请码生成失败，请刷新页面重试', [], true); ?>
                                    </small>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>

        <?php if (count($inviteEnabledRoots) === 0): ?>
            <div class="alert alert-secondary mb-0">
                <i class="fas fa-info-circle"></i>
                <?php echo $inviteText('cfclient.rootdomain_invite.no_roots', '当前没有需要邀请码的根域名', [], true); ?>
            </div>
        <?php endif; ?>
    </div>
</div>

<script>
function copyInviteCode(rootdomain) {
    const inputId = 'invite_code_' + rootdomain;
    const input = document.getElementById(inputId);
    if (!input) {
        return;
    }
    
    input.select();
    input.setSelectionRange(0, 99999); // For mobile devices
    
    try {
        const successful = document.execCommand('copy');
        if (successful) {
            // 显示复制成功提示
            const originalValue = input.value;
            const btn = input.nextElementSibling;
            const originalHTML = btn.innerHTML;
            
            btn.innerHTML = '<i class="fas fa-check"></i>';
            btn.classList.remove('btn-outline-primary');
            btn.classList.add('btn-success');
            
            setTimeout(() => {
                btn.innerHTML = originalHTML;
                btn.classList.remove('btn-success');
                btn.classList.add('btn-outline-primary');
            }, 2000);
        } else {
            alert('复制失败，请手动复制');
        }
    } catch (err) {
        // Fallback for modern browsers
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(input.value).then(() => {
                const btn = input.nextElementSibling;
                const originalHTML = btn.innerHTML;
                
                btn.innerHTML = '<i class="fas fa-check"></i>';
                btn.classList.remove('btn-outline-primary');
                btn.classList.add('btn-success');
                
                setTimeout(() => {
                    btn.innerHTML = originalHTML;
                    btn.classList.remove('btn-success');
                    btn.classList.add('btn-outline-primary');
                }, 2000);
            }).catch(() => {
                alert('复制失败，请手动复制');
            });
        } else {
            alert('您的浏览器不支持自动复制，请手动复制邀请码');
        }
    }
}
</script>
