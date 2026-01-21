<?php
// phpcs:ignoreFile

declare(strict_types=1);

use WHMCS\Database\Capsule;

/**
 * 域名邀请码服务
 * 
 * 负责管理根域名级别的邀请码注册功能
 * - 邀请码生成和管理
 * - 邀请码验证和使用
 * - 邀请日志记录
 */
class CfDomainInviteService
{
    private static ?self $instance = null;

    public static function instance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * 生成邀请码（10位字母+数字）
     * 移除容易混淆的字符：0, O, I, 1
     */
    public function generateInviteCode(): string
    {
        $characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        $code = '';
        for ($i = 0; $i < 10; $i++) {
            $code .= $characters[random_int(0, strlen($characters) - 1)];
        }
        return $code;
    }

    /**
     * 为用户和根域名获取或创建邀请码
     * 
     * @param int $userid 用户ID
     * @param string $rootdomain 根域名
     * @return array 邀请码信息
     */
    public function getUserInviteCode(int $userid, string $rootdomain): array
    {
        $rootdomain = strtolower(trim($rootdomain));

        // 检查是否已有可用的邀请码
        $existing = Capsule::table('mod_cloudflare_domain_invite_codes')
            ->where('userid', $userid)
            ->where('rootdomain', $rootdomain)
            ->where('status', 'active')
            ->where(function($q) {
                $q->whereNull('expires_at')
                  ->orWhere('expires_at', '>', date('Y-m-d H:i:s'));
            })
            ->first();

        if ($existing && $existing->used_count < $existing->max_uses) {
            return [
                'id' => $existing->id,
                'code' => $existing->code,
                'used_count' => $existing->used_count,
                'max_uses' => $existing->max_uses,
                'status' => $existing->status,
            ];
        }

        // 创建新的邀请码
        return $this->createInviteCode($userid, $rootdomain);
    }

    /**
     * 创建新邀请码
     * 
     * @param int $userid 用户ID
     * @param string $rootdomain 根域名
     * @param int $maxUses 最大使用次数
     * @return array 邀请码信息
     */
    private function createInviteCode(int $userid, string $rootdomain, int $maxUses = 1): array
    {
        $rootdomain = strtolower(trim($rootdomain));
        $code = $this->generateInviteCode();
        
        // 确保唯一性，最多尝试5次
        $attempts = 0;
        while ($attempts < 5 && Capsule::table('mod_cloudflare_domain_invite_codes')->where('code', $code)->exists()) {
            $code = $this->generateInviteCode();
            $attempts++;
        }

        if ($attempts >= 5) {
            throw new \RuntimeException('Failed to generate unique invite code');
        }

        $now = date('Y-m-d H:i:s');
        $id = Capsule::table('mod_cloudflare_domain_invite_codes')->insertGetId([
            'userid' => $userid,
            'rootdomain' => $rootdomain,
            'code' => $code,
            'used_count' => 0,
            'max_uses' => $maxUses,
            'expires_at' => null,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return [
            'id' => $id,
            'code' => $code,
            'used_count' => 0,
            'max_uses' => $maxUses,
            'status' => 'active',
        ];
    }

    /**
     * 验证邀请码
     * 
     * @param string $code 邀请码
     * @param string $rootdomain 根域名
     * @param int $inviteeUserId 被邀请人用户ID
     * @return array 验证结果
     */
    public function validateInviteCode(string $code, string $rootdomain, int $inviteeUserId): array
    {
        $code = strtoupper(trim($code));
        $rootdomain = strtolower(trim($rootdomain));

        if ($code === '') {
            return ['valid' => false, 'error' => '邀请码不能为空'];
        }

        if (strlen($code) !== 10) {
            return ['valid' => false, 'error' => '邀请码格式错误'];
        }

        // 查找邀请码
        $invite = Capsule::table('mod_cloudflare_domain_invite_codes')
            ->where('code', $code)
            ->where('rootdomain', $rootdomain)
            ->first();

        if (!$invite) {
            return ['valid' => false, 'error' => '邀请码不存在或不适用于该根域名'];
        }

        // 检查状态
        if ($invite->status !== 'active') {
            return ['valid' => false, 'error' => '邀请码已失效'];
        }

        // 检查是否过期
        if ($invite->expires_at && strtotime($invite->expires_at) < time()) {
            Capsule::table('mod_cloudflare_domain_invite_codes')
                ->where('id', $invite->id)
                ->update(['status' => 'expired', 'updated_at' => date('Y-m-d H:i:s')]);
            return ['valid' => false, 'error' => '邀请码已过期'];
        }

        // 检查使用次数
        if ($invite->used_count >= $invite->max_uses) {
            Capsule::table('mod_cloudflare_domain_invite_codes')
                ->where('id', $invite->id)
                ->update(['status' => 'exhausted', 'updated_at' => date('Y-m-d H:i:s')]);
            return ['valid' => false, 'error' => '邀请码已用完'];
        }

        // 不能用自己的邀请码
        if ($invite->userid == $inviteeUserId) {
            return ['valid' => false, 'error' => '不能使用自己的邀请码'];
        }

        // 检查邀请人是否达到邀请上限
        try {
            $settings = function_exists('cf_get_module_settings_cached') 
                ? cf_get_module_settings_cached() 
                : [];
            $maxInvites = (int)($settings['max_domain_invites_per_user'] ?? 0);
            
            if ($maxInvites > 0) {
                $inviterInviteCount = Capsule::table('mod_cloudflare_domain_invite_logs')
                    ->where('inviter_userid', $invite->userid)
                    ->where('rootdomain', $rootdomain)
                    ->count();
                
                if ($inviterInviteCount >= $maxInvites) {
                    return ['valid' => false, 'error' => '邀请人已达到邀请上限（' . $maxInvites . '人）'];
                }
            }
        } catch (\Throwable $e) {
            // 配置读取失败不阻止验证
        }

        // 检查被邀请人是否已经用过此根域名的邀请码
        $alreadyUsed = Capsule::table('mod_cloudflare_domain_invite_logs')
            ->where('invitee_userid', $inviteeUserId)
            ->where('rootdomain', $rootdomain)
            ->exists();

        if ($alreadyUsed) {
            return ['valid' => false, 'error' => '您已经使用过该根域名的邀请码'];
        }

        return [
            'valid' => true,
            'invite_id' => $invite->id,
            'inviter_userid' => $invite->userid,
            'code' => $invite->code,
        ];
    }

    /**
     * 使用邀请码
     * 
     * @param int $inviteId 邀请码ID
     * @param int $inviterUserId 邀请人ID
     * @param int $inviteeUserId 被邀请人ID
     * @param string $rootdomain 根域名
     * @param string $subdomain 子域名
     * @param int|null $subdomainId 子域名ID
     * @throws \RuntimeException
     */
    public function useInviteCode(
        int $inviteId,
        int $inviterUserId,
        int $inviteeUserId,
        string $rootdomain,
        string $subdomain,
        ?int $subdomainId = null
    ): void {
        Capsule::transaction(function() use ($inviteId, $inviterUserId, $inviteeUserId, $rootdomain, $subdomain, $subdomainId) {
            // 锁定并更新邀请码使用次数
            $invite = Capsule::table('mod_cloudflare_domain_invite_codes')
                ->where('id', $inviteId)
                ->lockForUpdate()
                ->first();

            if (!$invite) {
                throw new \RuntimeException('邀请码不存在');
            }

            if ($invite->status !== 'active') {
                throw new \RuntimeException('邀请码已失效');
            }

            if ($invite->used_count >= $invite->max_uses) {
                throw new \RuntimeException('邀请码已用完');
            }

            $newUsedCount = $invite->used_count + 1;
            $newStatus = $newUsedCount >= $invite->max_uses ? 'exhausted' : 'active';

            Capsule::table('mod_cloudflare_domain_invite_codes')
                ->where('id', $inviteId)
                ->update([
                    'used_count' => $newUsedCount,
                    'status' => $newStatus,
                    'updated_at' => date('Y-m-d H:i:s'),
                ]);

            // 获取被邀请人邮箱
            $inviteeEmail = Capsule::table('tblclients')
                ->where('id', $inviteeUserId)
                ->value('email');

            // 记录日志
            Capsule::table('mod_cloudflare_domain_invite_logs')->insert([
                'invite_code_id' => $inviteId,
                'code' => $invite->code,
                'inviter_userid' => $inviterUserId,
                'invitee_userid' => $inviteeUserId,
                'invitee_email' => $inviteeEmail,
                'rootdomain' => strtolower($rootdomain),
                'subdomain' => strtolower($subdomain),
                'subdomain_id' => $subdomainId,
                'ip_address' => $_SERVER['REMOTE_ADDR'] ?? null,
                'created_at' => date('Y-m-d H:i:s'),
            ]);

            // 如果邀请码用完，自动为邀请人生成新的邀请码
            if ($newStatus === 'exhausted') {
                try {
                    $this->createInviteCode($inviterUserId, $rootdomain, 1);
                } catch (\Throwable $e) {
                    // 生成新邀请码失败不影响主流程
                    if (function_exists('cfmod_report_exception')) {
                        cfmod_report_exception('domain_invite_auto_refresh', $e);
                    }
                }
            }
        });
    }

    /**
     * 检查根域名是否需要邀请码
     * 
     * @param string $rootdomain 根域名
     * @return bool
     */
    public function isInviteRequired(string $rootdomain): bool
    {
        try {
            if (!Capsule::schema()->hasTable('mod_cloudflare_rootdomains')) {
                return false;
            }

            $result = Capsule::table('mod_cloudflare_rootdomains')
                ->whereRaw('LOWER(domain) = ?', [strtolower(trim($rootdomain))])
                ->value('require_invite_code');

            return (bool)$result;
        } catch (\Throwable $e) {
            return false;
        }
    }

    /**
     * 获取所有需要邀请码的根域名
     * 
     * @return array
     */
    public function getInviteRequiredRootdomains(): array
    {
        try {
            if (!Capsule::schema()->hasTable('mod_cloudflare_rootdomains')) {
                return [];
            }

            $domains = Capsule::table('mod_cloudflare_rootdomains')
                ->where('require_invite_code', 1)
                ->where('status', 'active')
                ->pluck('domain')
                ->toArray();

            return array_map('strtolower', $domains);
        } catch (\Throwable $e) {
            return [];
        }
    }

    /**
     * 获取邀请日志
     * 
     * @param array $filters 过滤条件
     * @param int $page 页码
     * @param int $perPage 每页数量
     * @return array
     */
    public function getInviteLogs(array $filters = [], int $page = 1, int $perPage = 50): array
    {
        try {
            if (!Capsule::schema()->hasTable('mod_cloudflare_domain_invite_logs')) {
                return [
                    'logs' => [],
                    'total' => 0,
                    'page' => 1,
                    'perPage' => $perPage,
                    'totalPages' => 0,
                ];
            }

            $query = Capsule::table('mod_cloudflare_domain_invite_logs as log')
                ->leftJoin('tblclients as inviter', 'log.inviter_userid', '=', 'inviter.id')
                ->leftJoin('tblclients as invitee', 'log.invitee_userid', '=', 'invitee.id')
                ->select(
                    'log.*',
                    'inviter.email as inviter_email',
                    'inviter.firstname as inviter_firstname',
                    'inviter.lastname as inviter_lastname',
                    'invitee.firstname as invitee_firstname',
                    'invitee.lastname as invitee_lastname'
                );

            // 搜索过滤
            if (!empty($filters['code'])) {
                $query->where('log.code', 'like', '%' . $filters['code'] . '%');
            }
            if (!empty($filters['rootdomain'])) {
                $query->where('log.rootdomain', 'like', '%' . $filters['rootdomain'] . '%');
            }
            if (!empty($filters['invitee_email'])) {
                $query->where('log.invitee_email', 'like', '%' . $filters['invitee_email'] . '%');
            }
            if (!empty($filters['inviter_userid'])) {
                $query->where('log.inviter_userid', (int)$filters['inviter_userid']);
            }

            $total = $query->count();
            
            $page = max(1, $page);
            $perPage = max(1, min(200, $perPage));
            
            $logs = $query->orderBy('log.created_at', 'desc')
                ->skip(($page - 1) * $perPage)
                ->take($perPage)
                ->get();

            return [
                'logs' => $logs,
                'total' => $total,
                'page' => $page,
                'perPage' => $perPage,
                'totalPages' => $total > 0 ? (int)ceil($total / $perPage) : 0,
            ];
        } catch (\Throwable $e) {
            return [
                'logs' => [],
                'total' => 0,
                'page' => 1,
                'perPage' => $perPage,
                'totalPages' => 0,
                'error' => $e->getMessage(),
            ];
        }
    }

    /**
     * 获取用户的邀请统计
     * 
     * @param int $userid 用户ID
     * @param string|null $rootdomain 根域名（可选）
     * @return array
     */
    public function getUserInviteStats(int $userid, ?string $rootdomain = null): array
    {
        try {
            if (!Capsule::schema()->hasTable('mod_cloudflare_domain_invite_logs')) {
                return [
                    'total_invited' => 0,
                    'by_rootdomain' => [],
                ];
            }

            $query = Capsule::table('mod_cloudflare_domain_invite_logs')
                ->where('inviter_userid', $userid);

            if ($rootdomain !== null) {
                $query->where('rootdomain', strtolower(trim($rootdomain)));
            }

            $total = $query->count();

            $byDomain = Capsule::table('mod_cloudflare_domain_invite_logs')
                ->where('inviter_userid', $userid)
                ->select('rootdomain', Capsule::raw('COUNT(*) as count'))
                ->groupBy('rootdomain')
                ->get()
                ->mapWithKeys(function($item) {
                    return [$item->rootdomain => $item->count];
                })
                ->toArray();

            return [
                'total_invited' => $total,
                'by_rootdomain' => $byDomain,
            ];
        } catch (\Throwable $e) {
            return [
                'total_invited' => 0,
                'by_rootdomain' => [],
                'error' => $e->getMessage(),
            ];
        }
    }

    /**
     * 批量为用户生成邀请码
     * 
     * @param int $userid 用户ID
     * @param array $rootdomains 根域名列表
     * @return array
     */
    public function batchGenerateInviteCodes(int $userid, array $rootdomains): array
    {
        $results = [];
        foreach ($rootdomains as $rootdomain) {
            try {
                $results[$rootdomain] = $this->getUserInviteCode($userid, $rootdomain);
            } catch (\Throwable $e) {
                $results[$rootdomain] = [
                    'error' => $e->getMessage(),
                ];
            }
        }
        return $results;
    }

    /**
     * 清理过期的邀请码
     * 
     * @param int $batchSize 批量大小
     * @return int 清理数量
     */
    public function cleanupExpiredCodes(int $batchSize = 100): int
    {
        try {
            if (!Capsule::schema()->hasTable('mod_cloudflare_domain_invite_codes')) {
                return 0;
            }

            return Capsule::table('mod_cloudflare_domain_invite_codes')
                ->where('status', 'active')
                ->whereNotNull('expires_at')
                ->where('expires_at', '<', date('Y-m-d H:i:s'))
                ->limit($batchSize)
                ->update([
                    'status' => 'expired',
                    'updated_at' => date('Y-m-d H:i:s'),
                ]);
        } catch (\Throwable $e) {
            return 0;
        }
    }
}
