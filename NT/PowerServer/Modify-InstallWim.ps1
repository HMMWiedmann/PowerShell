function Modify-InstallWim
{
    param 
    ( 
        [Parameter(Mandatory = $true)]
        [string]$installwim,

        [Parameter(Mandatory = $true)]
        [string]$Index,

        [Parameter(Mandatory = $true)]
        [string]$MountPath,

        [Parameter]
        [string]$UpdatePath,

        [Parameter]
        [string]$DriverFolderPath,

        [Parameter]
        [string]$ToRemoveApps
    )

    # Mount Windows Image
    if (Test-Path $MountPath)
    {}
    else
    {   
        New-Item -ItemType Directory -Path C:\ -Name Mount
    }

    # Image in $Mountpath öffnen
    Mount-WindowsImage -Path $MountPath -ImagePath $installwim -Index $Index

    # Treiber installieren
    Add-WindowsDriver -Path $MountPath -Driver $DriverFolderPath -Recurse 

    # Updates installieren
    Add-WindowsPackage -Path $MountPath -PackagePath $UpdatePath 

    # Apps deinstallieren
    $AllApps = Get-ProvisionedAppxPackage -Path $MountPath
    $AllApps | Where-Object DisplayName -Like $ToRemoveApps | Remove-ProvisionedAppxPackage

    Dismount-WindowsImage -Path $MountPath -Save 

    Remove-Item $MountPath
}