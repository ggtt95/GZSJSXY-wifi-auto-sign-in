# =====================================================================================
# XX学校无线认证脚本（仅适用于本校网络）
# =====================================================================================
Add-Type -AssemblyName System.Web

# =====================================================================================
# 环境变量配置（必须设置！）
# =====================================================================================
$userId = $Env:USER_ID       # 用户账号（学号/工号）
$passwd = $Env:USER_PASSWD   # 登录密码
$targetSSID = $Env:TARGET_SSID  # 目标WiFi名称（如：GZSJSXY）

# =====================================================================================
# 固定参数（XX学校专用，勿修改！）
# =====================================================================================
$baseUrl = "http://172.18.0.199/webauth.do"  # 认证服务器地址（本校固定）
$wlanacip = "172.18.0.198"                   # 接入控制器IP（本校固定）
$wlanacname = "GZSJS"                        # 接入点标识（本校固定）
$vlan = "103"                                # VLAN标识（本校固定）
$defaultUrl = "http://www.msftconnecttest.com"  # 回调URL（本校固定）

# =====================================================================================
# 自动化参数获取
# =====================================================================================
# 获取WLAN接口信息
$wifiAdapter = Get-NetAdapter | Where-Object { $_.Name -eq "WLAN" -and $_.Status -eq "Up" }
if (-not $wifiAdapter) {
    Write-Host "错误：未找到活动的 WLAN 接口" -ForegroundColor Red
    exit
}

$macAddress = $wifiAdapter.MacAddress.Replace("-", ":").ToLower()
$wlanUserIP = (Get-NetIPAddress -InterfaceIndex $wifiAdapter.ifIndex -AddressFamily IPv4).IPAddress

# =====================================================================================
# 安全性验证
# =====================================================================================
# 检查是否连接到目标WiFi
$wifiSSID = (netsh wlan show interfaces | Select-String "SSID").Line.Split(":")[1].Trim()
if ($wifiSSID -ne $targetSSID) {
    Write-Host "错误：当前连接的WiFi不是目标网络（当前：$wifiSSID，目标：$targetSSID）" -ForegroundColor Red
    exit
}

# =====================================================================================
# 请求构造
# =====================================================================================
# 构造GET参数（本校固定格式）
$queryParams = @{
    wlanacip     = $wlanacip       # 接入控制器IP（固定）
    wlanacname   = $wlanacname     # 接入点标识（固定）
    wlanuserip   = $wlanUserIP     # 用户IP（动态获取）
    mac          = $macAddress     # MAC地址（动态获取）
    vlan         = $vlan           # VLAN标识（固定）
    url          = $defaultUrl     # 回调URL（固定）
}

# 生成 URL 编码的查询字符串
$paramList = @()
foreach ($key in $queryParams.Keys) {
    $encodedKey = $key
    $encodedValue = [System.Web.HttpUtility]::UrlEncode($queryParams[$key])
    $paramList += "$encodedKey=$encodedValue"
}
$queryString = $paramList -join "&"
$queryString = $queryString -replace "%3a", "%3A"  # 修正冒号编码

$fullUrl = "$baseUrl`?$queryString"
Write-Host "完整请求 URL: $fullUrl" -ForegroundColor Yellow

# 构造POST请求体（本校固定格式）
$body = @{
    scheme         = "http"          # 协议类型（固定）
    serverIp       = "172.18.0.199:80"  # 服务器IP:端口（固定）
    hostIp         = "http://127.0.0.1:8082/"  # 主机地址（固定）
    auth_type      = "0"             # 认证类型（固定）
    templatetype   = "1"             # 模板类型（固定）
    isBindMac      = "bindmac"       # MAC绑定标识（固定）
    remInfo        = "on"            # 附加信息（固定）
    userId         = $userId         # 用户账号（来自环境变量）
    passwd         = $passwd         # 用户密码（来自环境变量）
}

$headers = @{
    "Content-Type" = "application/x-www-form-urlencoded"
    "User-Agent"   = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0"
}

# =====================================================================================
# 执行认证
# =====================================================================================
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

try {
    Write-Host "正在初始化会话..." -ForegroundColor Cyan
    $initialResponse = Invoke-WebRequest -Uri $baseUrl -WebSession $session

    Write-Host "正在发送认证请求..." -ForegroundColor Cyan
    $response = Invoke-WebRequest -Uri $fullUrl `
        -Method Post `
        -Body $body `
        -Headers $headers `
        -WebSession $session `
        -TimeoutSec 10

    # 解析响应结果
    $content = $response.Content
    if ($content -match "没有找到对应的portal模板记录") {
        Write-Host "认证失败：未找到对应的 portal 模板！" -ForegroundColor Red
    } elseif ($content -match "认证成功") {
        Write-Host "认证成功！" -ForegroundColor Green
    } else {
        Write-Host "认证结果未知：`n$content" -ForegroundColor Yellow
    }

    # 验证网络连通性
    Write-Host "正在测试网络连接..." -ForegroundColor Cyan
    $testResponse = Invoke-WebRequest -Uri "https://www.baidu.com" -WebSession $session -TimeoutSec 10
    if ($testResponse.StatusCode -eq 200) {
        Write-Host "网络已生效，可正常访问互联网！" -ForegroundColor Green
    } else {
        Write-Host "网络测试失败（状态码：$($testResponse.StatusCode)）" -ForegroundColor Red
    }
} catch {
    Write-Host "发生错误：$($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "按任意键退出..." -NoNewline
Read-Host