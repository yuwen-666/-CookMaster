const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// 验证码存储（内存，生产环境建议用Redis）
const codeStore = new Map();

// ============ 配置区域 ============
// 请修改为你的邮箱SMTP配置
// QQ邮箱设置方法：设置 -> 账户 -> POP3/IMAP/SMTP服务 -> 开启SMTP -> 生成授权码
const SMTP_CONFIG = {
  // QQ邮箱配置
  host: 'smtp.qq.com',
  port: 465,
  secure: true,
  auth: {
    user: 'YOUR_EMAIL@qq.com',      // TODO: 替换为你的QQ邮箱
    pass: 'YOUR_SMTP_AUTH_CODE'      // TODO: 替换为你的SMTP授权码
  }
};

// 发件人显示名称
const FROM_NAME = '智能菜谱推荐助手';

// 验证码有效期（毫秒）
const CODE_TTL = 5 * 60 * 1000; // 5分钟
// ================================

// 创建邮件传输器
const transporter = nodemailer.createTransport(SMTP_CONFIG);

// 生成6位随机验证码
function generateCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// 发送验证码API
app.post('/api/send-code', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ success: false, message: '邮箱地址不能为空' });
  }

  // 验证邮箱格式
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ success: false, message: '邮箱格式不正确' });
  }

  // 生成验证码
  const code = generateCode();

  // 存储验证码
  codeStore.set(email, {
    code: code,
    timestamp: Date.now()
  });

  // 邮件内容
  const mailOptions = {
    from: `"${FROM_NAME}" <${SMTP_CONFIG.auth.user}>`,
    to: email,
    subject: '【智能菜谱推荐助手】邮箱验证码',
    html: `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <div style="background: linear-gradient(135deg, #FF6B35, #FF8A5C); padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
          <h1 style="color: white; margin: 0;">🍳 智能菜谱推荐助手</h1>
        </div>
        <div style="background: #ffffff; padding: 30px; border: 1px solid #eee; border-radius: 0 0 10px 10px;">
          <h2 style="color: #333;">邮箱验证码</h2>
          <p style="color: #666; font-size: 16px;">您正在注册智能菜谱推荐助手账号，验证码如下：</p>
          <div style="background: #FFF3E0; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
            <span style="font-size: 36px; font-weight: bold; color: #FF6B35; letter-spacing: 8px;">${code}</span>
          </div>
          <p style="color: #999; font-size: 14px;">验证码有效期为5分钟，请勿泄露给他人。</p>
          <p style="color: #999; font-size: 14px;">如果这不是您的操作，请忽略此邮件。</p>
        </div>
        <div style="text-align: center; padding: 20px; color: #999; font-size: 12px;">
          <p>© 2024 智能菜谱推荐助手 - 让烹饪更简单</p>
        </div>
      </div>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`[邮件已发送] ${email} -> 验证码: ${code}`);
    res.json({ success: true, message: '验证码已发送到您的邮箱' });
  } catch (error) {
    console.error('发送邮件失败:', error);
    res.status(500).json({ success: false, message: '邮件发送失败，请稍后重试' });
  }
});

// 验证验证码API
app.post('/api/verify-code', (req, res) => {
  const { email, code } = req.body;

  if (!email || !code) {
    return res.status(400).json({ success: false, message: '邮箱和验证码不能为空' });
  }

  const record = codeStore.get(email);

  if (!record) {
    return res.json({ success: false, message: '请先获取验证码' });
  }

  // 检查是否过期
  if (Date.now() - record.timestamp > CODE_TTL) {
    codeStore.delete(email);
    return res.json({ success: false, message: '验证码已过期，请重新获取' });
  }

  // 检查验证码
  if (record.code !== code) {
    return res.json({ success: false, message: '验证码错误' });
  }

  // 验证成功，删除验证码
  codeStore.delete(email);
  res.json({ success: true, message: '验证成功' });
});

// 健康检查
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: '邮件服务运行正常' });
});

// 启动服务器
const PORT = 3000;
app.listen(PORT, () => {
  console.log('===========================================');
  console.log('  📧 邮箱验证码服务已启动');
  console.log(`  🌐 服务地址: http://localhost:${PORT}`);
  console.log('===========================================');
  console.log('');
  console.log('⚠️  使用前请配置SMTP信息:');
  console.log('   1. 打开 server.js 文件');
  console.log('   2. 修改 SMTP_CONFIG 中的邮箱和授权码');
  console.log('   3. 重启服务');
  console.log('');
  console.log('📮 QQ邮箱授权码获取方式:');
  console.log('   1. 登录 QQ 邮箱网页版');
  console.log('   2. 设置 -> 账户 -> POP3/IMAP/SMTP服务');
  console.log('   3. 开启 SMTP 服务');
  console.log('   4. 生成授权码');
  console.log('');
});
