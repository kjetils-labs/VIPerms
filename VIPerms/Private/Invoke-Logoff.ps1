function Invoke-Logoff {
    <#
    .SYNOPSIS
    Logout of the authenticated vCenter MOB web session and clear up the Script variable VIPerms.
    #>
    
    BEGIN {
        $ProPref            = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"
    } #BEGIN

    PROCESS {
        try {
            [String]$Uri = "https://$($Script:VIPerms.Server)/invsvc/mob3/logout"
            $Res         = Invoke-WebRequest -Uri $Uri -WebSession $Script:VIPerms.WebSession -Method GET
            $Script::VIPerms.WebSession   = $null
            $Script::VIPerms.SessionNonce = $null
    
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

} #function Invoke-Logoff
