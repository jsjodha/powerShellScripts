$dupes = @()
[System.Collections.ArrayList]$arrBefore = Get-Content U:\before.txt
[System.Collections.ArrayList]$arrAfter = Get-Content U:\after.txt

$i = 0
foreach ($itemBefore in $arrBefore) {
    $i++
    Write-Progress -Activity "Comparing lines in the two files..." `
        -PercentComplete (($i / $arrBefore.count) * 100) -CurrentOperation $itemBefore
    if ($arrAfter -match $itemBefore) {
        $arrAfter.Remove($itemBefore)
        $dupes += $itemBefore
    }
}