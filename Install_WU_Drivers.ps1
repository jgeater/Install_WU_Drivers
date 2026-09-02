#region Logging Setup
$LogDir  = "C:\PKGLOG"
$LogFile = Join-Path -Path $LogDir -ChildPath "Install_WU_Drivers.log"

if (-not (Test-Path -Path $LogDir))
{
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

function Write-Log
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry     = "[$Timestamp] [$Level] $Message"

    Write-Host $Entry
    Add-Content -Path $LogFile -Value $Entry
}
#endregion

Write-Log "===== Script started ====="

$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()

Write-Log "Searching for driver updates..."

$SearchResult = $Searcher.Search(
    "IsInstalled=0 and Type='Driver'"
)

if ($SearchResult.Updates.Count -eq 0)
{
    Write-Log "No driver updates found."
    Write-Log "===== Script completed ====="
    return
}

$UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl

foreach ($Update in $SearchResult.Updates)
{
    Write-Log "Found: $($Update.Title)"
    $UpdatesToInstall.Add($Update) | Out-Null
}

Write-Log "Downloading Drivers..."

$Downloader = $Session.CreateUpdateDownloader()
$Downloader.Updates = $UpdatesToInstall
$Downloader.Download()

Write-Log "Installing Drivers..."

$Installer = $Session.CreateUpdateInstaller()
$Installer.Updates = $UpdatesToInstall

$Result = $Installer.Install()

# Map WUA result codes to human-readable text
$ResultCodeMap = @{
    0 = "Not Started"
    1 = "In Progress"
    2 = "Succeeded"
    3 = "Succeeded With Errors"
    4 = "Failed"
    5 = "Aborted"
}

$InstallSummary = @()

for ($i = 0; $i -lt $UpdatesToInstall.Count; $i++)
{
    $UpdateTitle  = $UpdatesToInstall.Item($i).Title
    $UpdateResult = $Result.GetUpdateResult($i)
    $ResultText   = $ResultCodeMap[$UpdateResult.ResultCode]
    $Succeeded    = ($UpdateResult.ResultCode -eq 2)

    if ($Succeeded)
    {
        Write-Log "Installed: $UpdateTitle - $ResultText"
    }
    else
    {
        Write-Log "Installed: $UpdateTitle - $ResultText (HResult: $($UpdateResult.HResult))" -Level "WARNING"
    }

    $InstallSummary += [PSCustomObject]@{
        Title     = $UpdateTitle
        Succeeded = $Succeeded
        Result    = $ResultText
    }
}

Write-Log "----- Installation Summary -----"
foreach ($Item in $InstallSummary)
{
    $Status = if ($Item.Succeeded) { "SUCCESS" } else { "FAILED" }
    Write-Log ("{0}: {1} ({2})" -f $Status, $Item.Title, $Item.Result)
}

$SucceededCount = ($InstallSummary | Where-Object { $_.Succeeded }).Count
$FailedCount     = ($InstallSummary | Where-Object { -not $_.Succeeded }).Count
Write-Log "Summary: $SucceededCount succeeded, $FailedCount failed out of $($InstallSummary.Count) total."
Write-Log "---------------------------------"

Write-Log "Result Code: $($Result.ResultCode)"
Write-Log "Reboot Required: $($Result.RebootRequired)"

if ($Result.RebootRequired)
{
    Write-Log "Reboot suppressed."
}

Write-Log "===== Script completed ====="