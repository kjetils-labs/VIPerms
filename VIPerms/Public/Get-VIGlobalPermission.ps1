function Get-VIGlobalPermission {
    <#
        .SYNOPSIS
            Get one or more global permissions.

        .DESCRIPTION
            Return information relating to one or more global permissions. This is not very performant as it literally
            parses the html from the response of the vSphere MOB to get the information. This appears to be the
            only way to achieve this currently as there is no public API available for vSphere global permissions.

        .PARAMETER SkipCertificateCheck
            Skip certificate verification.

        .EXAMPLE
            Get-VIGlobalPermission

            Principal                                                            PrincipalType Role      Propagate
            ---------                                                            ------------- ----      ---------
            VSPHERE.LOCAL\vpxd-extension-b2df90b0-1e03-11e6-b844-005056bf2aaa    User          Admin     true
            VSPHERE.LOCAL\vpxd-b2df90b0-1e03-11e6-b844-005056bf2aaa              User          Admin     true
            VSPHERE.LOCAL\vsphere-webclient-b2df90b0-1e03-11e6-b844-005056bf2aaa User          Admin     true
            VSPHERE.LOCAL\Administrators                                         Group         Admin     true
            VSPHERE.LOCAL\Administrator                                          User          Admin     true
    #>


    param(
        [Parameter(
            Position  = 0
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

            $VIRoles = Get-VIMobRole

            Invoke-Login

            [String]$Uri  = "https://$($Script:VIPerms.Server)/invsvc/mob3/?moid=authorizationService&" + "method=AuthorizationService.GetGlobalAccessControlList"
            [String]$Body = "vmware-session-nonce=$($Script:VIPerms.SessionNonce)"

            $Params = @{
                Uri        = $Uri
                WebSession = $Script:VIPerms.WebSession
                Method     = "POST"
                Body       = $Body
            } #Params

            $Res                   = Invoke-WebRequest @Params
            [Hashtable]$RoleLookup = @{}

            foreach ($VIRole in $VIRoles) {
                $RoleLookup[$($VIRole.Id)] = $VIRole.Name
            } #Foreach

            $Table = $Res.ParsedHtml.body.getElementsByTagName("table")[3]
            $Td    = $Table.getElementsByTagName("tr")[4].getElementsByTagName("td")[2]
            $Li    = $Td.getElementsByTagName("ul")[0].getElementsByTagName("li")

            foreach ($Item in $Li) {
                if ($Item.innerHTML.StartsWith("<TABLE")) {
                    $PrinTable     = $Item.getElementsByTagName("tr")[3].getElementsByTagName("td")[2].getElementsByTagName("table")[0]
                    $Principal     = $PrinTable.getElementsByTagName("tr")[4].getElementsByTagName("td")[2].innerText
                    $IsGroup       = $PrinTable.getElementsByTagName("tr")[3].getElementsByTagName("td")[2].innerText
                    $PrincipalType = switch ($IsGroup) {
                        $true {"Group"}
                        $false {"User"}
                    } #$PrincipalType = switch ($IsGroup)

                    $Role      = $Item.getElementsByTagName("tr")[10].getElementsByTagName("li")[0].innerText
                    $Propagate = $Item.getElementsByTagName("tr")[9].getElementsByTagName("td")[2].innerText

                    Write-Output (@{
                        Principal     = $Principal
                        PrincipalType = $PrincipalType
                        Role          = $RoleLookup.$($Role)
                        Propagate     = $Propagate
                    })
                } #if
            } #foreach
            Invoke-Logoff
            if ($SkipCertificateCheck -or $Script:VIPerms.SkipCertificateCheck) {
                Set-CertPolicy -ResetToDefault
            } #if

        } #try
        catch {
            $Err                = $_
            $ProgressPreference = $ProPref
            throw $Err
        } #catch

    } #PROCESS

    END {
        $ProgressPreference = $ProPref
    } #END

} #function Get-VIGlobalPermission
