$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$HistoryCount = $Searcher.GetTotalHistoryCount()
# http://msdn.microsoft.com/en-us/library/windows/desktop/aa386532%28v=vs.85%29.aspx
$Searcher.QueryHistory(0,$HistoryCount) | ForEach-Object -Process {
    $Title = $null
    if($_.Title -match "\(KB\d{6,7}\)"){
        # Split returns an array of strings
        $Title = ($_.Title -split '.*\((?<KB>KB\d{6,7})\)')[1]
    }else{
        $Title = $_.Title
    }
    # http://msdn.microsoft.com/en-us/library/windows/desktop/aa387095%28v=vs.85%29.aspx
    $Result = $null
    Switch ($_.ResultCode)
    {
        0 { $Result = 'NotStarted'}
        1 { $Result = 'InProgress' }
        2 { $Result = 'Succeeded' }
        3 { $Result = 'SucceededWithErrors' }
        4 { $Result = 'Failed' }
        5 { $Result = 'Aborted' }
        default { $Result = $_ }
    }
    New-Object -TypeName PSObject -Property @{
        InstalledOn = Get-Date -Date $_.Date;
        Title = $Title;
        Name = $_.Title;
        Status = $Result
    }
 
} | Sort-Object -Descending:$true -Property InstalledOn | Select-Object -Property * -ExcludeProperty Name | Format-Table -AutoSize -Wrap

##################################################################################################################################################################

# Gives a list of all Microsoft Updates sorted by KB number/HotfixID
# By Tom Arbuthnot. Lyncdup.com

$wu = New-Object -com "Microsoft.Update.Searcher"
$totalupdates = $wu.GetTotalHistoryCount()
$all = $wu.QueryHistory(0,$totalupdates)

# Define a new array to gather output
 $OutputCollection =  @()
Foreach ($update in $all)
{
    $string = $update.title
    $Regex = "KB\d*"
    $KB = $string | Select-String -Pattern $regex | Select-Object { $_.Matches }
        $output = New-Object -TypeName PSobject
        $output | add-member NoteProperty "HotFixID" -value $KB.' $_.Matches '.Value
        $output | add-member NoteProperty "Title" -value $string
        $OutputCollection += $output
}

# Oupput the collection sorted and formatted:
$OutputCollection | Sort-Object HotFixID | Format-Table -AutoSize
Write-Host "$($OutputCollection.Count) Updates Found" 

# If you want to output the collection as an object, just remove the two lines above and replace them with "$OutputCollection"

# credit/thanks:
# http://blogs.technet.com/b/tmintner/archive/2006/07/07/440729.aspx
# http://www.gfi.com/blog/windows-powershell-extracting-strings-using-regular-expressions/