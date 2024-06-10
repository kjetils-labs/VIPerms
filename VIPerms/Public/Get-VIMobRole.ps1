function Get-VIMobRole {
    <#
        .SYNOPSIS
            Get roles via the Managed Object Browser (MOB)

        .DESCRIPTION
            Retrieve all available roles from the vCenter MOB. This is not the most effective way of retrieving this
            information. If you are using PowerCLI you should use the built in Get-VIRole CmdLet instead.

        .PARAMETER SkipCertificateCheck
            Skip certificate verification.

        .EXAMPLE
            Get-VIMobRole
    #>

    param(
        [Parameter(
            Position = 0
        )]
        [Switch] $SkipCertificateCheck
    )

    BEGIN {

        $ProPref            = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"

    } #BEGIN
    PROCESS {

        try {

            if ($SkipCertificateCheck -or $Script:VIPerms.SkipCertificateCheck) {
                Set-CertPolicy -SkipCertificateCheck
            }
            Invoke-Login
            [String]$Uri  = "https://$($Script:VIPerms.Server)/invsvc/mob3/?moid=authorizationService&method=AuthorizationService.GetRoles"
            [String]$Body = "vmware-session-nonce=$($Script:VIPerms.SessionNonce)"
            $Params = @{
                Uri        = $Uri
                WebSession = $Script:VIPerms.WebSession
                Method     = "POST"
                Body       = $Body
            }
            $Res   = Invoke-WebRequest @Params
            $Table = $Res.ParsedHtml.body.getElementsByTagName("table")[3]
            $Td    = $Table.getElementsByTagName("tr")[4].getElementsByTagName("td")[2]
            $Li    = $Td.getElementsByTagName("ul")[0].getElementsByTagName("li")

            foreach ($Item in $Li) {

                if ($Item.innerHTML.StartsWith("<TABLE")) {
                    $Description = $Item.getElementsByTagName("tr")[1].getElementsByTagName("td")[2].innerText
                    $Id          = $Item.getElementsByTagName("tr")[4].getElementsByTagName("td")[2].innerText
                    $Name        = $Item.getElementsByTagName("tr")[5].getElementsByTagName("td")[2].innerText

                    Write-Output (@{
                        Name        = $Name
                        Description = $Description
                        Id          = $Id
                    })
                } #if

            } #foreach

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

} #function Get-VIMobRole
