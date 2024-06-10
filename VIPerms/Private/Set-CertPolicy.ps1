function Set-CertPolicy {
    <#
    .SYNOPSIS
    Ignore SSL verification.

    .DESCRIPTION
    Using a custom .NET type, override SSL verification policies.

    #>

    param (
        [Switch]$SkipCertificateCheck
    )

    try {
        if ($SkipCertificateCheck) {
            if ($PSVersionTable.PSEdition -eq 'Core') {
                # Invoke-restmethod provide Skip certcheck param in powershell core
                $Script:PSDefaultParameterValues = @{
                    "invoke-restmethod:SkipCertificateCheck" = $true
                    "invoke-webrequest:SkipCertificateCheck" = $true
                } #$Script:PSDefaultParameterValues
            } #if
            else {
                    Add-Type -TypeDefinition  @"
                    using System.Net;
                    using System.Security.Cryptography.X509Certificates;
                    public class TrustAllCertsPolicy : ICertificatePolicy {
                        public bool CheckValidationResult(
                            ServicePoint srvPoint, X509Certificate certificate,
                            WebRequest request, int certificateProblem) {
                            return true;
                        }
                    }
"@
                [Net.ServicePointManager]::CertificatePolicy = [TrustAllCertsPolicy]::new()
            } #else
        } #if $SkipCertificateCheck
    } #try
    catch {
        $Err = $_
        throw $Err
    } #catch
} #function Set-CertPolicy
