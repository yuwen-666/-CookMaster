# 🔧 SDK版本不匹配修复指南

## 问题说明
错误信息：`应用的compatibleSdkVersion和releaseType与设备上的apiVersion和releaseType不匹配`

## 解决方案

### 步骤1：查看你的设备API版本

**方法A：在DevEco Studio中查看**
1. 连接设备或启动模拟器
2. 底部面板 → `Device Manager` → 查看设备信息
3. 记录 `API Version` 号（如 12、13、14、16）

**方法B：在设备上查看**
1. 手机设置 → 关于手机 → 软件版本
2. 查看 HarmonyOS 版本号

### 步骤2：查看你的DevEco Studio SDK版本

1. 打开 DevEco Studio
2. 菜单栏 → `File` → `Settings` → `SDK`
3. 查看已安装的 SDK 版本号

### 步骤3：修改 build-profile.json5

打开 `CookMaster/build-profile.json5`，修改以下内容：

```json
{
  "app": {
    "products": [
      {
        "name": "default",
        "targetSdkVersion": "你的SDK版本",
        "compatibleSdkVersion": "你的设备API版本",
        "runtimeOS": "HarmonyOS"
      }
    ]
  }
}
```

### 常见版本对照表

| HarmonyOS 版本 | API Version | SDK 版本号 |
|---------------|-------------|-----------|
| HarmonyOS 4.0 | API 9 | 4.0.0(9) |
| HarmonyOS 4.2 | API 11 | 4.2.0(11) |
| HarmonyOS 5.0 | API 12 | 5.0.0(12) |
| HarmonyOS 5.0.3 | API 13 | 5.0.3(13) |
| HarmonyOS 5.1 | API 16 | 5.1.0(16) |

### 示例配置

**如果你的设备是 API 12 (HarmonyOS 5.0)：**
```json
"targetSdkVersion": "5.0.0(12)",
"compatibleSdkVersion": "5.0.0(12)"
```

**如果你的设备是 API 13 (HarmonyOS 5.0.3)：**
```json
"targetSdkVersion": "5.0.3(13)",
"compatibleSdkVersion": "5.0.3(13)"
```

**如果你的设备是 API 16 (HarmonyOS 5.1)：**
```json
"targetSdkVersion": "5.1.0(16)",
"compatibleSdkVersion": "5.1.0(16)"
```

### 步骤4：重新同步项目

修改完成后：
1. 在DevEco Studio中点击 `File` → `Sync and Refresh Project`
2. 等待同步完成
3. 重新运行项目

## 注意事项

- `targetSdkVersion` 必须 >= `compatibleSdkVersion`
- `compatibleSdkVersion` 必须 <= 设备的API版本
- 如果不确定，可以先用较低版本，如 `5.0.0(12)`
