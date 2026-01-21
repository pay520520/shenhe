<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>域名邀请注册日志 - Domain Hub</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <style>
        body {
            background-color: #f8f9fa;
            padding: 20px;
        }
        .main-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .back-button {
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container-fluid">
        <!-- 返回按钮 -->
        <div class="back-button">
            <a href="<?php echo htmlspecialchars($modulelink); ?>" class="btn btn-secondary">
                <i class="fas fa-arrow-left"></i> 返回管理主页
            </a>
        </div>

        <!-- 页面标题 -->
        <div class="main-header">
            <h2 class="mb-0">
                <i class="fas fa-history"></i> 域名邀请注册日志
            </h2>
            <p class="mb-0 mt-2">查看所有通过邀请码注册的域名记录</p>
        </div>

        <!-- 包含日志内容 -->
        <?php include __DIR__ . '/admin/partials/domain_invite_logs.tpl'; ?>
    </div>

    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
