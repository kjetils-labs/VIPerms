function Remove-VIGlobalPermission {
    <#
        .SYNOPSIS
            Delete a global permission for a specific user/group.

        .DESCRIPTION
            Delete a global permission for a specific user/group.

        .PARAMETER Name
            Specify the name of user or group including the domain.

        .PARAMETER IsGroup
            Specify whether the target is a group object or not.

        .PARAMETER SkipCertificateCheck
            Skip certificate verification.

        .EXAMPLE
            Remove-VIGlobalPermission -Name "VSPHERE.LOCAL\Administrator"

        .EXAMPLE
            Remove-VIGlobalPermission -Name "VSPHERE.LOCAL\group-of-users" -IsGroup
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
        [Switch]$SkipCertificateCheck
    )

    BEGIN {
        $ProPref = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"
    } #BEGIN

    PROCESS {

        try {

            if ($SkipCertificateCheck -or $Script:VIPerms.SkipCertificateCheck) {
                Set-CertPolicy -SkipCertificateCheck
            } #if

            Invoke-Login

            [String]$Uri = "https://$($Script:VIPerms.Server)/invsvc/mob3/?moid=authorizationService&method=AuthorizationService.RemoveGlobalAccess"

            $Body = (
                "vmware-session-nonce=$($Script:VIPerms.SessionNonce)&" +
                "principals=%3Cprincipals%3E%0D%0A+++%3Cname%3E$([Uri]::EscapeUriString($Name))" +
                "%3C%2Fname%3E%0D%0A+++%3Cgroup%3E$($IsGroup.IsPresent)%3C%2Fgroup%3E%0D%0A%3C%2Fprincipals%3E"
            ) #Body

            $Params = @{
                Uri        = $Uri
                WebSession = $Script:VIPerms.WebSession
                Method     = "POST"
                Body       = $Body
            } #Params

            [Void](Invoke-WebRequest @Params)

            Invoke-Logoff
            if ($SkipCertificateCheck -or $Script:VIPerms.SkipCertificateCheck) {
                Set-CertPolicy -ResetToDefault
            } #if

        } #try
        catch {
            $Err = $_
            $ProgressPreference = $ProPref
            throw $Err
        } #catch

    } #PROCESS

    END {
        $ProgressPreference = $ProPref
    } #END

} #function Remove-VIGlobalPermission
