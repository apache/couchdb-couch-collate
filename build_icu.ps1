param([switch]$clean)

$ICU_ZIP = "icu4c-4_8_1-Win32-msvc10.zip"
$ICU_URL="http://download.icu-project.org/files/icu4c/4.8.1"

$DISTDIR="${pwd}\.dists"
$STATICLIBS="${pwd}\.libs"
$ICUDIR="${STATICLIBS}\icu"

#
# improved remove-item -recurse -force
# thanks to http://serverfault.com/questions/199921/powershell-remove-force
#
function rmrf($directory = $(throw "Required parameter missing")) {
    if ((test-path $directory) -and -not
            (gi $directory | ? { $_.PSIsContainer })) {
        throw ("rmrf called on non-directory.");
    }

    $finished = $false;
    $attemptsLeft = 3;

    do {
        if (test-path $directory) {
            rm $directory -recurse -force 2>&1 | out-null
        }
        if (test-path $directory) {
            Start-Sleep -Milliseconds 500
            $attemptsLeft = $attemptsLeft - 1
        } else {
            $finished = $true
        }
    } while (-not $finished -and $attemptsLeft -gt 0)

    if (test-path $directory) {
        throw ("Unable to fully remove directory " + $directory)
    }
}


#
# main
#
if ($clean -eq $true) {
    write-host "==> icu (clean)"
    rmrf($STATICLIBS)
    rmrf($DISTDIR)
} else {
    write-host "==> icu (binary-download)"
    rmrf($STATICLIBS)
    rmrf($DISTDIR)
    md $STATICLIBS -ea silentlycontinue > $null
    md $DISTDIR -ea silentlycontinue > $null

    # download the zip
    $source = "${ICU_URL}/${ICU_ZIP}"
    $dest = "${DISTDIR}\${ICU_ZIP}"
    if (-not (test-path $dest)) {
        write-host "==> Fetch ${ICU_ZIP} to ${dest}"
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($source, $dest)
    }

    # unpack the zip
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($dest)
    foreach($item in $zip.items())
    {
        $shell.Namespace($STATICLIBS).copyhere($item)
    }
}
