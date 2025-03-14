#广州市技师学院（科技城校区）学校无线网络认证脚本（仅限本校使用）

## 参数说明
### 1. 固定参数（勿修改！）
| 参数名           | 含义                                                                 |
|------------------|----------------------------------------------------------------------|
| `baseUrl`        | 认证服务器地址，本校固定为 `http://172.18.0.199/webauth.do`          |
| `wlanacip`       | 接入控制器IP地址，本校固定为 `172.18.0.198`                          |
| `wlanacname`     | 接入点标识符，本校固定为 `GZSJS`                                     |
| `vlan`           | VLAN网络标识，本校固定为 `103`                                      |
| `defaultUrl`     | 认证成功后的回调URL，本校固定为 `http://www.msftconnecttest.com`     |

### 2. 动态参数（自动获取）
| 参数名           | 含义                                                                 |
|------------------|----------------------------------------------------------------------|
| `wlanUserIP`     | 用户设备的IP地址，由脚本自动获取                                     |
| `macAddress`     | 设备的MAC地址，由脚本自动获取                                       |

### 3. 环境变量配置（必须设置！）
```powershell
[System.Environment]::SetEnvironmentVariable("USER_ID", "你的账号", "User")
[System.Environment]::SetEnvironmentVariable("USER_PASSWD", "你的密码", "User")
[System.Environment]::SetEnvironmentVariable("TARGET_SSID", "GZSJSXY", "User")

本脚本仅适用于广州市技师学院（科技城校区）的宿舍的GZSJSXY网络：
如果你的学校网络环境不同（如认证服务器地址、VLAN标识等），必须自行抓包分析。
固定参数（如 baseUrl、vlan）是针对广州市技师学院（科技城校区）学校的，其他学校需替换为自己的参数。
如何获取自己的参数？
抓包分析：
连接到目标WiFi后，尝试访问任意网页。
使用浏览器开发者工具（F12 → Network）记录请求。
对比脚本中的 queryParams 和实际请求的 URL 参数。
示例：
实际URL: http://172.18.0.199/webauth.do?wlanacip=172.18.0.198&wlanuserip=192.168.1.100...
baseUrl 是 http://172.18.0.199/webauth.do
wlanacip 是 172.18.0.198
遇到问题？
如果提示 未找到 portal 模板，说明参数与学校要求不匹配。
需自行调整 queryParams 和 body 中的固定参数。

注意：该项目的代码及readme部分完全由ai编写，我只提供想法，还有代码已经经过ai的处理变得可能会出现很多问题，如果遇到问题可以把代码和报错和readme发给任意深度思考ai

如果想要在连接上网络自动化运行脚本：
Windows：
按下win键并随便输入一个字弹出搜索面板，搜索任务计划程序，打开后点击右边的创建任务，
然后写个名字，勾选下面的使用最高权限运行，
点击触发器选项卡，添加触发器。开始任务项设置成发生事件时，日志选择Microsoft-Windows-NetworkProfile/Operational，事件ID为10000。
点击操作选项卡，添加操作，操作为启动程序，程序为powershell.exe，参数为-ExecutionPolicy Bypass -File "你的脚本文件地址"。
然后就好了，但是这样会导致连什么网都弹出来那个脚本。