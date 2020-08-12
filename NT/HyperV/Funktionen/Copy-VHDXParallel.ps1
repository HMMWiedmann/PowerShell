workflow Copy-VHDXParallel
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [string]$ParentdiskPath,

        [Parameter(Mandatory = $true)]
        [string]$VMRootLetter,
    
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$VMNames
    )

    foreach -parallel ($Name in $VMNames) 
    {
        "Copying VM: $Name"
        $null = New-Item -Type Directory -Path "$($VMRootLetter):\$($Name)" -Force
        Copy-Item -Path $ParentdiskPath -Destination "$($VMRootLetter):\$($Name)\$($Name).vhdx" -Force
    }
}