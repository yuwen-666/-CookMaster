# 📧 邮箱验证码服务

这是智能菜谱推荐助手的邮箱验证码后端服务。

## 🚀 快速开始

### 1. 安装依赖

```bash
cd email-server
npm install
```

### 2. 配置SMTP

打开 `server.js` 文件，修改以下配置：

```javascript
const SMTP_CONFIG = {
  host: 'smtp.qq.com',           // SMTP服务器
  port: 465,                      // 端口
  secure: true,                   // SSL
  auth: {
    user: '你的QQ邮箱@qq.com',   // 你的邮箱
    pass: '你的授权码'            // 授权码（不是密码）
  }
};
```

### 3. 启动服务

```bash
npm start
```

看到以下信息表示启动成功：
```
===========================================
  📧 邮箱验证码服务已启动
  🌐 服务地址: http://localhost:3000
===========================================
```

## 📮 QQ邮箱授权码获取方式

1. 登录 [QQ邮箱网页版](https://mail.qq.com/)
2. 点击 **设置** -> **账户**
3. 找到 **POP3/IMAP/SMTP/Exchange/CardDAV/CalDAV服务**
4. 开启 **POP3/SMTP服务** 或 **IMAP/SMTP服务**
5. 点击 **生成授权码**
6. 按提示发送短信验证
7. 获得16位授权码

## 🔌 API接口

### 发送验证码

```
POST /api/send-code
Content-Type: application/json

{
  "email": "user@example.com"
}

// 响应
{
  "success": true,
  "message": "验证码已发送到您的邮箱"
}
```

### 验证验证码

```
POST /api/verify-code
Content-Type: application/json

{
  "email": "user@example.com",
  "code": "123456"
}

// 响应
{
  "success": true,
  "message": "验证成功"
}
```

### 健康检查

```
GET /api/health

// 响应
{
  "status": "ok",
  "message": "邮件服务运行正常"
}
```

## 📧 支持的邮箱服务商

| 邮箱 | SMTP服务器 | 端口 |
|------|-----------|------|
| QQ邮箱 | smtp.qq.com | 465 |
| 163邮箱 | smtp.163.com | 465 |
| Gmail | smtp.gmail.com | 465 |
| Outlook | smtp.office365.com | 587 |

## ⚠️ 注意事项

1. **授权码不是密码** - QQ邮箱需要使用授权码而非登录密码
2. **服务需保持运行** - 验证码发送依赖此服务
3. **局域网访问** - 手机和电脑需在同一WiFi下
4. **防火墙** - 确保端口3000未被占用

## 🔧 常见问题

### Q: 发送失败怎么办？
A: 检查以下几点：
- 授权码是否正确
- 邮箱SMTP服务是否已开启
- 网络是否正常

### Q: 手机收不到验证码？
A: 检查以下几点：
- 服务是否正在运行
- 手机和电脑是否在同一网络
- 检查垃圾邮件文件夹

### Q: 如何在真机上测试？
A: 
1. 查看电脑IP地址（命令行输入 `ipconfig`）
2. 修改App中的API地址为 `http://你的IP:3000`
3. 确保手机和电脑在同一WiFi下
