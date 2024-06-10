function New-VIGlobalPermission {
    <#
        .SYNOPSIS
            Add a global permission for a user/group.

        .DESCRIPTION
            Creates a global permission assigning either a user or group to a specific role.

        .PARAMETER Name
            Specify the name of user or group including the domain.

        .PARAMETER IsGroup
            Specify whether the target is a group object or not.

        .PARAMETER RoleId
            Specify the identifier for the specific role to assign to the global permission.

        .PARAMETER Propagate
            Specify whether the permission should propagate to all children objects or not.

        .PARAMETER SkipCertificateCheck
            Skip certificate verification.

        .EXAMPLE
            New-VIGlobalPermission -Name "VSPHERE.LOCAL\joe-bloggs" -RoleId -1

        .EXAMPLE
            New-VIGlobalPermission -Name "VSPHERE.LOCAL\group-of-users" -IsGroup -RoleId -1

        .EXAMPLE
            New-VIGlobalPermission -Name "VSPHERE.LOCAL\joe-bloggs" -RoleId -1 -Propagate:$false

        .OUTPUTS
            None
    #>


    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [String]$Name,

        [Parameter(
            Position = 1
        )]
        [Switch]$IsGroup,

        [Parameter(
            Position = 2
        )]
        [String]$RoleId,

        [Parameter(
            Position = 3
        )]
        [Switch]$Propagate = [Switch]::Present,

        [Parameter(
            Position = 4
        )]
        [Switch]$SkipCertificateCheck
    )

    BEGIN {

        $ProPref            = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"

    } #BEGIN

    PROCESS {

        try {

            if ($SkipCertificateCheck -or $Script:VIPerms.SkipCertificateCheck) {
                Set-CertPolicy -SkipCertificateCheck
            } #if

            Invoke-Login
            [String]$Uri = "https://$($Script:VIPerms.Server)/invsvc/mob3/?moid=authorizationService&method=AuthorizationService.AddGlobalAccessControlList"

            [String]$Body = (
                "vmware-session-nonce=$($Script:VIPerms.SessionNonce)&" +
                "permissions=%3Cpermissions%3E%0D%0A+++%3Cprincipal%3E%0D%0A++++++" +
                "%3Cname%3E$([Uri]::EscapeUriString($Name))%3C%2Fname%3E" +
                "%0D%0A++++++%3Cgroup%3E$($IsGroup.IsPresent)%3C%2Fgroup%3E%0D%0A+++%3C%2Fprincipal%3E%0D%0A+++" +
                "%3Croles%3E$RoleId%3C%2Froles%3E%0D%0A+++" +
                "%3Cpropagate%3E$($Propagate.IsPresent)%3C%2Fpropagate%3E%0D%0A%3C%2Fpermissions%3E"
            ) #body

            [Hashtable]$Params = @{
                Uri        = $Uri
                WebSession = $Script:VIPerms.WebSession
                Method     = "POST"
                Body       = $Body
            } #param

            [Void](Invoke-WebRequest @Params)

            Invoke-Logoff

            if ($SkipCertificateCheck -or $Script:VIPerms.SkipCertificateCheck) {
                Set-CertPolicy -ResetToDefault
            } #if

        } #Try
        catch {
            $Err = $_
            $ProgressPreference = $ProPref
            throw $Err
        } #catch

    } #PROCESS

    END {
        $ProgressPreference = $ProPref
    } #END

} #function New-VIGlobalPermission
