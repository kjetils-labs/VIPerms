function Invoke-Login {
    <#
    .SYNOPSIS
    Authenticate against vCenter MOB

    .DESCRIPTION
    Authenticate against vCenter MOB and grab the vmware-session-nonce. This is then stored in the global 
    VIPerms hashtable along with the session variable from the web request.   
    #>

    BEGIN {
        $ProPref            = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"
    } #BEGIN

    PROCESS {
    
        try {
            if (!($Script:VIPerms.Server) -or ([String]::IsNullOrEmpty($Script:VIPerms.Server)) -or
                !($Script:VIPerms.Credential) -or ([String]::IsNullOrEmpty($Script:VIPerms.Credential))) {
                throw "Please authenticate using Connect-VIMobServer first!"
            }
            [String]$Uri = "https://$($Script:VIPerms.Server)/invsvc/mob3/?moid=authorizationService&method=AuthorizationService.GetRoles"
            
            # Initial login to vSphere MOB to store session variable
            [Hashtable]$Params = @{
                Uri             = $Uri
                SessionVariable = "MobSession"
                Credential      = $Script:VIPerms.Credential
                Method          = "GET"
            }
            $Res = Invoke-WebRequest @Params
            
            # Extract hidden vmware-session-nonce which must be included in future requests to prevent CSRF error
            # Credit to https://blog.netnerds.net/2013/07/use-powershell-to-keep-a-cookiejar-and-post-to-a-web-form/ for
            # parsing vmware-session-nonce via Powershell
            if ($Res.StatusCode -eq 200) {
                [void]($Res -match 'name="vmware-session-nonce" type="hidden" value="?([^\s^"]+)"')
                $Script:VIPerms.SessionNonce = $Matches[1]
                $Script:VIPerms.WebSession   = $MobSession
            } #if 
            else {
                throw "Failed to login to vSphere MOB"
            } #else

        } #try
        catch {
            $Err = $_
            throw $Err
        } #catch
    } #PROCESS

    END {
        $ProgressPreference = $ProPref
    } #EMD


} #function Invoke-Login
