# Umbenennung der VHDX nachdem Update

function Update-VHDX 
{
    param 
    (
        # Path to VHDX
        [Parameter(Mandatory = $true)]
        [string]
        $VHDXPath,

        # Path to UpdatePackage
        [Parameter(Mandatory = $true)]
        [string]
        $UpdatePath,

        # Path where the UpdatePackage will be extracted
        [Parameter(Mandatory = $false)]
        [string]
        $ScratchDirectory
    )
    
    $VHDXName = (Get-Item -Path $VHDXPath).Name
    $Update = (Get-Item -Path $UpdatePath).Name

    Write-Verbose "Mounting $VHDXName."
    $PSDrive = Mount-VHD -Path $VHDXPath -Passthru
    $VolumeLetter = (Get-Partition -DiskNumber $PSDrive.Number).where{ $PSItem.Size -gt 30GB }.DriveLetter

    if($ScratchDirectory)
    {
        if(!(Test-Path -Path $ScratchDirectory))
        {
            $null = New-Item -Path $ScratchDirectory -ItemType Directory -Force
        }

        Write-Verbose "Adding Package $Update to $VHDXName."
        $null = Add-WindowsPackage -PackagePath $UpdatePath -Path "$($VolumeLetter):\" -ScratchDirectory $ScratchDirectory

        Remove-Item -Path $ScratchDirectory -Force -Confirm:$false
    }
    else
    {
        Write-Verbose "Adding Package $Update to $VHDXName."
        $null = Add-WindowsPackage -PackagePath $UpdatePath -Path "$($VolumeLetter):\"
    }

    Write-Verbose "Dismounting $VHDXName."
    $null = Dismount-VHD -DiskNumber $PSDrive.Number

    Write-Verbose "Dismounted $VHDXName successfully."

    Write-Host "$($VHDXName): Updated To $((Get-WindowsImage -ImagePath $VHDXPath -Index 1).Version)"
}

function Update-VHDX2
{
    param 
    (
        # Path to VHDX
        [Parameter(Mandatory = $true)]
        [string]
        $VHDXPath,

        # Path to UpdatePackage
        [Parameter(Mandatory = $true)]
        [string]
        $UpdatePath
    )

    $VHDXName = (Get-Item -Path $VHDXPath).Name
    $Update = (Get-Item -Path $UpdatePath).Name
    $Guid = New-Guid

    $MountPath = New-Item -Path "$env:windir\Temp\Mount\$($Guid.Guid)" -ItemType Directory
    Write-Verbose "Mounting $VHDXName in $MountPath."
    Mount-WindowsImage -ImagePath $VHDXPath -Path $MountPath.FullName

    Write-Verbose "Adding Package $Update to $VHDXName."
    Add-WindowsPackage -PackagePath $VHDXPath -Path $MountPath
    
    Write-Verbose "Dismounting $VHDXName"
    Dismount-WindowsImage -Path $VHDXPath -Save -CheckIntegrity

    Write-Verbose "Dismounted $VHDXName successfully."

    Write-Verbose "Deleting Directory $($MountPath.FullName)"
    Remove-Item -Path $MountPath.FullName -Recurse -Force 

    if((Get-ChildItem -Path "$env:windir\Temp\Mount\") -eq $null)
    {
        Write-Verbose "Deleting Directory $("$env:windir\Temp\Mount")"
        Remove-Item -Path "$env:windir\Temp\Mount" -Force
    }
}