#Checking for admin privs. This isn't always necessary, but allows using this script in protected game folders.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
    exit;
}

#Checking for dependencies
if (!(Get-Command $PSScriptRoot\dependencies\magick.exe -errorAction SilentlyContinue) -or !(Get-Command $PSScriptRoot\dependencies\texconv.exe -errorAction SilentlyContinue) -or !(Get-Command $PSScriptRoot\dependencies\texdiag.exe -errorAction SilentlyContinue))
{
    Write-Host "Dependencies not found. Make sure to put the dependencies folder in the same place as the script." -ForegroundColor Yellow
    Start-Sleep 10
    return
}

#The message at startup
echo "Working... This may take a while. This window will close itself when finished."

#Workaround to escape special characters in the file path
Out-File -FilePath C:\ddsgeneratortempcache.txt -InputObject $PSScriptRoot -Encoding ASCII -Width 50

#Getting the images in the folder this script is located in, as well as its subfolders
$images = Get-ChildItem -literalPath (get-item -literalPath (gc 'C:\ddsgeneratortempcache.txt')) -filter("*.??g") -Recurse | % { $_.FullName }

#This variable allows changing the amount of threads to use. Default is [int]$env:NUMBER_OF_PROCESSORS
$MaxThreads = [int]$env:NUMBER_OF_PROCESSORS

#Script with the ImageMagick operation that actually generates the DDS files
$Scriptblock = {
    param($png,$scriptpath)

    #valid texdiag results from [9] of the array
    $format1 = "       format = B8G8R8A8_UNORM_SRGB"
    $format2 = "       format = R8G8B8A8_UNORM_SRGB"
    $format3 = "       format = B8G8R8X8_UNORM_SRGB"
    #$format4 = "       format = B8G8R8A8_UNORM"
    #$format5 = "       format = R8G8B8A8_UNORM"
    #$format6 = "       format = B8G8R8X8_UNORM"

    #Uncommenting the following disables MipMaps with texconv.
    #This reduces filesize and memory usage by 25%, but also worsens zooming performance and quality.
    #$MipMaps = '-m','1'

    #Same as above, but ImageMagick
    #$MipMapIM = '-define','dds:mipmaps=0'
    
    #Quoting. Not sure if necessary tbh
    $pngQuoted = '"' + $png + '"'

    #Outputpath
    $output = Split-Path -Path $png
    #Outputfile
    $dds = $png -replace ".{4}$",'.dds'
    $ddsQuoted = '"' + $dds + '"'

    #Checking for transparency
    $opaque = & $scriptpath\dependencies\magick.exe identify -format %[opaque] $pngQuoted

    #Checking colorspace. texconv can't convert this, so it's necessary here
    $texd = & $scriptpath\dependencies\texdiag.exe info $pngQuoted

    #texconv compression. -y allows overwriting, -vflip flips to fulfil the unity requirement, -fixbc4x4 tries to fix unsupported texture dimensions, -o is the output
    function futexconv { & $scriptpath\dependencies\texconv.exe $MipMaps $format -y -vflip -fixbc4x4 -o $output $pngQuoted }

    #ImageMagick compression
    function fuMagick { & $scriptpath\dependencies\magick.exe $pngQuoted -flip -define dds:compression=dxt1 $MipMapIM $ddsQuoted }

    #Fully opaque images get compressed with DXT1/BC1, others with BC7. DXT1 has a 50% lower size than BC7, but if quality is important using BC7 everywhere is possible too.
    if ($opaque -eq 'True') {

        #for B8G8R8A8_UNORM_SRGB etc convert to BC7_UNORM_SRGB
        if (($texd[9] -eq $format1) -or ($texd[9] -eq $format2) -or ($texd[9] -eq $format3)){
        #$format = '-f','BC1_UNORM_SRGB'

        #texconv apparently can't properly compress to DXT1 with SRGB, so we use ImageMagick here.
        #Why are all these compression tools from those big corporations so damn shit
        fuMagick

        #for B8G8R8A8_UNORM etc convert to BC7_UNORM. In this case, texconv works again.
        } else {
        $format = '-f','BC1_UNORM'
        futexconv
        }
    } else {

        #for B8G8R8A8_UNORM_SRGB etc convert to BC7_UNORM_SRGB
        if (($texd[9] -eq $format1) -or ($texd[9] -eq $format2)){
        $format = '-f','BC7_UNORM_SRGB'
        futexconv

        #for B8G8R8A8_UNORM etc convert to BC7_UNORM
        } else {
        $format = '-f','BC7_UNORM'
        futexconv
        }
    }
}

#MultiThreading
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
$RunspacePool.Open()
$jobs = New-Object System.Collections.ArrayList
$filepath = get-item -literalPath (gc 'C:\ddsgeneratortempcache.txt')

$images | ForEach {

    $PowerShell = [powershell]::Create()
    $PowerShell.RunspacePool = $RunspacePool
    [void]$PowerShell.AddScript($ScriptBlock).AddArgument($_).AddArgument($filepath)
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

#Delete the cache file of the workaround
Remove-Item -LiteralPath 'C:\ddsgeneratortempcache.txt' -Force

#Cleanup
$return = $jobs | ForEach {

    $_.PowerShell.EndInvoke($_.handle)

    $_.PowerShell.Dispose()

}

echo (“Successfully generated {0} files.” -f @($jobs | Where {
    
    $_.handle.iscompleted -eq ‘Completed’

    }).Count)

$jobs.clear()

Start-Sleep 7