#Checking for admin privs. This isn't always necessary, but allows using this script in protected game folders.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
    exit;
}

#Checking for ImageMagick
if (!(Get-Command Magick -errorAction SilentlyContinue))
{
    Write-Host "ImageMagick seems to not be installed. Get it from imagemagick.org, install it and try again." -ForegroundColor Yellow
    Start-Sleep 10
    return
}

#The message at startup
echo "Working... This may take a while. This window will close itself when finished."

#Workaround to escape special characters in the file path
Out-File -FilePath C:\ddsgeneratortempcache.txt -InputObject $PSScriptRoot -Encoding ASCII -Width 50

#Getting the images in the folder this script is located in, as well as its subfolders
$images = Get-ChildItem -literalPath (get-item -literalPath (gc 'C:\ddsgeneratortempcache.txt')) -filter("*.??g") -Recurse | % { $_.FullName }

#Delete the cache file of the workaround
Remove-Item -LiteralPath 'C:\ddsgeneratortempcache.txt' -Force

#This variable allows changing the amount of threads to use. Default is [int]$env:NUMBER_OF_PROCESSORS*2
$MaxThreads = [int]$env:NUMBER_OF_PROCESSORS*2

#Script with the ImageMagick operation that actually generates the DDS files
$Scriptblock = {
    param($png)

    #Normally, with the following setting commented out, ImageMagick generates the maximum number of mip levels for zooming to a size of 1x1
    #In theory, MipMaps increase file size by 33%, while increasing zooming performance and quality.
    #Rimworld however, sadly, somewhat struggles with MipMaps. Things start disappearing among other issues. This setting here is used to disable MipMaps.
    $MipMapSize = '-define','dds:mipmaps=0'
    
    #Output files get the same name as the input, with .png or .jpg replaced by .dds
    $dds = $png -replace ".{4}$",'.dds'

    #Quoting. Not sure if necessary tbh
    $ddsQuoted = '"' + $dds + '"'
    $pngQuoted = '"' + $png + '"'

    #Checking for transparency
    $opaque = Magick identify -format %[opaque] $pngQuoted

    #Fully opaque images get compressed with DXT1, others with DXT5
    if ($opaque -eq 'True') {
        $compression = 'dds:compression=dxt1'
    } else {
        $compression = 'dds:compression=dxt5'
    }
    Magick $pngQuoted -flip -define $compression $MipMapSize $ddsQuoted
}

#MultiThreading
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
$RunspacePool.Open()
$jobs = New-Object System.Collections.ArrayList

$images | ForEach {

    $PowerShell = [powershell]::Create()
    $PowerShell.RunspacePool = $RunspacePool
    [void]$PowerShell.AddScript($ScriptBlock).AddArgument($_)
    $Handle = $PowerShell.BeginInvoke()

    $temp = [PSCustomObject]@{
    PowerShell = $null
    Handle = $null
    }
    $temp.PowerShell = $PowerShell
    $temp.handle = $Handle
    [void]$jobs.Add($temp)
}

#Displaying a counter for remaining files
while ($Handle.IsCompleted -contains $false) {
	Start-Sleep 1
    echo (“Remaining Files: {0}” -f @($jobs | Where {
    
    $_.handle.iscompleted -ne ‘Completed’

    }).Count)
}

#Cleanup
$return = $jobs | ForEach {

    $_.PowerShell.EndInvoke($_.handle)

    $_.PowerShell.Dispose()

}

$jobs.clear()