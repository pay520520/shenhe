<?php
/**
 * 域名邀请注册日志
 * 
 * 数据来源：$cfAdminViewModel['domainInviteLogs']
 */

$inviteLogs = $cfAdminViewModel['domainInviteLogs'] ?? [
    'logs' => [],
    'total' => 0,
    'page' => 1,
    'perPage' => 50,
    'totalPages' => 0,
];

$searchCode = isset($_GET['search_code']) ? trim((string)$_GET['search_code']) : '';
$searchDomain = isset($_GET['search_domain']) ? trim((string)$_GET['search_domain']) : '';
$searchEmail = isset($_GET['search_email']) ? trim((string)$_GET['search_email']) : '';
$currentPage = $inviteLogs['page'] ?? 1;
?>

<div class="card mt-3">
    <div class="card-header">
        <h5 class="card-title mb-0">
            <i class="fas fa-history"></i> 域名邀请注册日志
            <?php if ($inviteLogs['total'] > 0): ?>
                <span class="badge badge-primary"><?php echo number_format($inviteLogs['total']); ?> 条记录</span>
            <?php endif; ?>
        </h5>
    </div>
    <div class="card-body">
        <!-- 搜索表单 -->
        <form method="get" class="mb-3">
            <input type="hidden" name="module" value="<?php echo htmlspecialchars(CF_MODULE_NAME); ?>">
            <input type="hidden" name="action" value="view_domain_invite_logs">
            
            <div class="row">
                <div class="col-md-3">
                    <div class="form-group">
                        <label class="sr-only" for="search_code">邀请码</label>
                        <input type="text" 
                               name="search_code" 
                               id="search_code"
                               class="form-control" 
                               placeholder="搜索邀请码" 
                               value="<?php echo htmlspecialchars($searchCode); ?>">
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="form-group">
                        <label class="sr-only" for="search_domain">根域名</label>
                        <input type="text" 
                               name="search_domain" 
                               id="search_domain"
                               class="form-control" 
                               placeholder="搜索根域名" 
                               value="<?php echo htmlspecialchars($searchDomain); ?>">
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="form-group">
                        <label class="sr-only" for="search_email">用户邮箱</label>
                        <input type="text" 
                               name="search_email" 
                               id="search_email"
                               class="form-control" 
                               placeholder="搜索用户邮箱" 
                               value="<?php echo htmlspecialchars($searchEmail); ?>">
                    </div>
                </div>
                <div class="col-md-3">
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-search"></i> 搜索
                    </button>
                    <a href="?module=<?php echo htmlspecialchars(CF_MODULE_NAME); ?>&action=view_domain_invite_logs" 
                       class="btn btn-secondary">
                        <i class="fas fa-redo"></i> 重置
                    </a>
                </div>
            </div>
        </form>

        <!-- 日志列表 -->
        <?php if (empty($inviteLogs['logs'])): ?>
            <div class="alert alert-info">
                <i class="fas fa-info-circle"></i> 
                <?php if ($searchCode || $searchDomain || $searchEmail): ?>
                    未找到匹配的邀请注册记录
                <?php else: ?>
                    暂无邀请注册记录
                <?php endif; ?>
            </div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover table-sm">
                    <thead class="thead-light">
                        <tr>
                            <th style="width: 50px;">ID</th>
                            <th style="width: 120px;">邀请码</th>
                            <th>邀请人</th>
                            <th>被邀请人</th>
                            <th>根域名</th>
                            <th>注册的子域名</th>
                            <th style="width: 100px;">IP地址</th>
                            <th style="width: 140px;">注册时间</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($inviteLogs['logs'] as $log): ?>
                        <tr>
                            <td><?php echo $log->id; ?></td>
                            <td>
                                <code style="font-size: 0.9em; letter-spacing: 1px;">
                                    <?php echo htmlspecialchars($log->code); ?>
                                </code>
                            </td>
                            <td>
                                <a href="clientssummary.php?userid=<?php echo $log->inviter_userid; ?>" 
                                   target="_blank"
                                   class="text-primary">
                                    <i class="fas fa-user"></i>
                                    <?php echo htmlspecialchars($log->inviter_email ?? 'User #' . $log->inviter_userid); ?>
                                </a>
                                <?php if ($log->inviter_firstname || $log->inviter_lastname): ?>
                                    <br>
                                    <small class="text-muted">
                                        <?php echo htmlspecialchars(trim($log->inviter_firstname . ' ' . $log->inviter_lastname)); ?>
                                    </small>
                                <?php endif; ?>
                            </td>
                            <td>
                                <a href="clientssummary.php?userid=<?php echo $log->invitee_userid; ?>" 
                                   target="_blank"
                                   class="text-success">
                                    <i class="fas fa-user-plus"></i>
                                    <?php echo htmlspecialchars($log->invitee_email ?? 'User #' . $log->invitee_userid); ?>
                                </a>
                                <?php if ($log->invitee_firstname || $log->invitee_lastname): ?>
                                    <br>
                                    <small class="text-muted">
                                        <?php echo htmlspecialchars(trim($log->invitee_firstname . ' ' . $log->invitee_lastname)); ?>
                                    </small>
                                <?php endif; ?>
                            </td>
                            <td>
                                <code class="text-info">
                                    <?php echo htmlspecialchars($log->rootdomain); ?>
                                </code>
                            </td>
                            <td>
                                <code style="font-size: 0.85em;">
                                    <?php echo htmlspecialchars($log->subdomain); ?>
                                </code>
                                <?php if ($log->subdomain_id): ?>
                                    <br>
                                    <small class="text-muted">ID: <?php echo $log->subdomain_id; ?></small>
                                <?php endif; ?>
                            </td>
                            <td>
                                <?php if ($log->ip_address): ?>
                                    <small class="text-monospace">
                                        <?php echo htmlspecialchars($log->ip_address); ?>
                                    </small>
                                <?php else: ?>
                                    <span class="text-muted">-</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <small class="text-muted">
                                    <?php echo $log->created_at; ?>
                                </small>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>

            <!-- 分页 -->
            <?php if ($inviteLogs['totalPages'] > 1): ?>
            <nav aria-label="邀请日志分页">
                <ul class="pagination justify-content-center">
                    <?php if ($currentPage > 1): ?>
                    <li class="page-item">
                        <a class="page-link" 
                           href="?module=<?php echo htmlspecialchars(CF_MODULE_NAME); ?>&action=view_domain_invite_logs&page=<?php echo ($currentPage - 1); ?><?php echo $searchCode ? '&search_code=' . urlencode($searchCode) : ''; ?><?php echo $searchDomain ? '&search_domain=' . urlencode($searchDomain) : ''; ?><?php echo $searchEmail ? '&search_email=' . urlencode($searchEmail) : ''; ?>">
                            <i class="fas fa-chevron-left"></i> 上一页
                        </a>
                    </li>
                    <?php endif; ?>

                    <?php 
                    $startPage = max(1, $currentPage - 2);
                    $endPage = min($inviteLogs['totalPages'], $currentPage + 2);
                    
                    if ($startPage > 1): ?>
                        <li class="page-item">
                            <a class="page-link" href="?module=<?php echo htmlspecialchars(CF_MODULE_NAME); ?>&action=view_domain_invite_logs&page=1<?php echo $searchCode ? '&search_code=' . urlencode($searchCode) : ''; ?><?php echo $searchDomain ? '&search_domain=' . urlencode($searchDomain) : ''; ?><?php echo $searchEmail ? '&search_email=' . urlencode($searchEmail) : ''; ?>">1</a>
                        </li>
                        <?php if ($startPage > 2): ?>
                            <li class="page-item disabled"><span class="page-link">...</span></li>
                        <?php endif; ?>
                    <?php endif; ?>

                    <?php for ($i = $startPage; $i <= $endPage; $i++): ?>
                    <li class="page-item <?php echo $i == $currentPage ? 'active' : ''; ?>">
                        <a class="page-link" 
                           href="?module=<?php echo htmlspecialchars(CF_MODULE_NAME); ?>&action=view_domain_invite_logs&page=<?php echo $i; ?><?php echo $searchCode ? '&search_code=' . urlencode($searchCode) : ''; ?><?php echo $searchDomain ? '&search_domain=' . urlencode($searchDomain) : ''; ?><?php echo $searchEmail ? '&search_email=' . urlencode($searchEmail) : ''; ?>">
                            <?php echo $i; ?>
                        </a>
                    </li>
                    <?php endfor; ?>

                    <?php if ($endPage < $inviteLogs['totalPages']): ?>
                        <?php if ($endPage < $inviteLogs['totalPages'] - 1): ?>
                            <li class="page-item disabled"><span class="page-link">...</span></li>
                        <?php endif; ?>
                        <li class="page-item">
                            <a class="page-link" href="?module=<?php echo htmlspecialchars(CF_MODULE_NAME); ?>&action=view_domain_invite_logs&page=<?php echo $inviteLogs['totalPages']; ?><?php echo $searchCode ? '&search_code=' . urlencode($searchCode) : ''; ?><?php echo $searchDomain ? '&search_domain=' . urlencode($searchDomain) : ''; ?><?php echo $searchEmail ? '&search_email=' . urlencode($searchEmail) : ''; ?>"><?php echo $inviteLogs['totalPages']; ?></a>
                        </li>
                    <?php endif; ?>

                    <?php if ($currentPage < $inviteLogs['totalPages']): ?>
                    <li class="page-item">
                        <a class="page-link" 
                           href="?module=<?php echo htmlspecialchars(CF_MODULE_NAME); ?>&action=view_domain_invite_logs&page=<?php echo ($currentPage + 1); ?><?php echo $searchCode ? '&search_code=' . urlencode($searchCode) : ''; ?><?php echo $searchDomain ? '&search_domain=' . urlencode($searchDomain) : ''; ?><?php echo $searchEmail ? '&search_email=' . urlencode($searchEmail) : ''; ?>">
                            下一页 <i class="fas fa-chevron-right"></i>
                        </a>
                    </li>
                    <?php endif; ?>
                </ul>
            </nav>
            <?php endif; ?>

            <!-- 统计信息 -->
            <div class="text-center text-muted mt-2">
                <small>
                    显示 <?php echo min(($currentPage - 1) * $inviteLogs['perPage'] + 1, $inviteLogs['total']); ?> 
                    - <?php echo min($currentPage * $inviteLogs['perPage'], $inviteLogs['total']); ?> 
                    / 共 <?php echo number_format($inviteLogs['total']); ?> 条记录
                </small>
            </div>
        <?php endif; ?>

        <!-- 说明 -->
        <div class="alert alert-info mt-3">
            <h6><i class="fas fa-info-circle"></i> 说明</h6>
            <ul class="mb-0">
                <li>此日志记录所有通过邀请码注册的域名</li>
                <li>点击用户邮箱可跳转到用户详情页面</li>
                <li>每个邀请码只能使用一次，使用后会自动为邀请人生成新的邀请码</li>
                <li>可以在"配置"页面设置每人最多可邀请好友数量</li>
            </ul>
        </div>
    </div>
</div>
