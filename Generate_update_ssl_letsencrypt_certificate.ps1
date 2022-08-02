<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>


param (
    [Parameter( Mandatory = $false  )]
    [string] $Sub_Domain_Name = "*", # '*' For wildcard certificates

    [Parameter( Mandatory = $false  )]
    [string] $Domain_Name = "web.some.website",

    [Parameter( Mandatory = $false  )]
    [string] $Resource_Group_Name = "Org",

    [Parameter( Mandatory = $false  )]
    [string] $Key_Vault_Name = "o-kv",
	
    [Parameter( Mandatory = $false  )]
    [string] $Contacts_email = "1234asd@gmail.com",

    [Parameter( Mandatory = $false )]
    [string] $Pfx_password = "password"

)


$full_domain = "$Sub_Domain_Name.$Domain_Name"


# login with identity
try {
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

# Get Service Principal informations
try {
    $tenantID = (Get-AzKeyVaultSecret -Vault $Key_Vault_Name -Name "tenantID" -AsPlainText)
    $subscriptionID = (Get-AzKeyVaultSecret -Vault $Key_Vault_Name -Name "subscriptionID" -AsPlainText)
    $ServicePrincipalID = (Get-AzKeyVaultSecret -Vault $Key_Vault_Name -Name "ServicePrincipalID" -AsPlainText) 
    $ServicePrincipalKey = (Get-AzKeyVaultSecret -Vault $Key_Vault_Name -Name "ServicePrincipalKey" -AsPlainText)
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Unable to get service principal information from key vault $Key_Vault_Name  > $errorMessage"
    throw $_
}


# Generate credentials to create an ssl certificate
$SPkey = ConvertTo-SecureString -String $ServicePrincipalKey -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServicePrincipalID, $SPkey

# Certificate arguments
$pArgs = @{
    AZSubscriptionId = $subscriptionID
    AZTenantId       = $tenantID 
    AZAppCred        = $Credential
}

# Generate new certificate
try {
    $certificat = (New-PACertificate $full_domain -Plugin Azure -PluginArgs $pArgs -AcceptTOS -Contact $Contacts_email -PfxPass $Pfx_password -Force)
    Write-Output "`nCertificat thumnbrint - $($certificat.Thumbprint)"
    $certificat
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Unable to generate SSL certificate for $full_domain`n> $errorMessage"
    throw $_
}


# Upload certificate to key vault
$kv_cert_name = ("$($certificat.AllSANs[0]).pfx" -replace "\.", "-" -replace "\*", "star")  # unable to use dots in the certificate name
Write-Output "`nImporting certificat to key vault $kv_cert_name"
try {
    Import-AzKeyVaultCertificate -VaultName $Key_Vault_Name -Name $kv_cert_name -FilePath $certificat.PfxFile -Password ( ConvertTo-SecureString -String $Pfx_password -AsPlainText -Force )
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Unable to upload certificate to key vault $Key_Vault_Name`n> $errorMessage"
    throw $_
}


# Get web app names
$Web_App_Names = ( Get-AzWebApp -ResourceGroupName $Resource_Group_Name ).Name

# Import certificate to app service (in Resource Group hidden types) # Only once per resource group
try {
    Write-Output "`nImporting certificat to resource group (to the first App service) - Certificate=$kv_cert_name"
    Import-AzWebAppKeyVaultCertificate -WebAppName $Web_App_Names[0] -KeyVaultName $Key_Vault_Name -CertName $kv_cert_name -ResourceGroupName $Resource_Group_Name
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Unable to Import certificat to resource group (app service - $($Web_App_Names[0]) )`n> $errorMessage"
    throw $_
}

#region    enumerate app services
foreach ($Web_App_Name in $Web_App_Names) {
    $Host_Name = ( Get-AzWebApp -ResourceGroupName $Resource_Group_Name -Name $Web_App_Name ).HostNames | Where-Object { $_ -like "*.$Domain_Name" }

    if ( $Host_Name ) {
        Write-Output "$Web_App_Name - DNS Zone configured, Zone name - $Host_Name"
        
        try {
            # Bind certificat to app service
            Write-Output "Binding certificate to app service`n"
            New-AzWebAppSSLBinding -ResourceGroupName $Resource_Group_Name -WebAppName $Web_App_Name -Name $full_domain -Thumbprint $($certificat.Thumbprint) 
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "Unable to bind certificate to $Web_App_Name`n> $errorMessage"
            throw $_
        }

    }
    else {
        Write-Output "`n$Web_App_Name web app DNS zone not configured" 
        #< no action required >
    }
}
#endregion enumerate app services



# $full_domain = "$Sub_Domain_Name.$Domain_Name"

# #$Site = Get-AzWebApp -ResourceGroupName $Resource_Group_Name -Name "innotest1"
# #$Site
# # New-AzWebAppSSLBinding `
# #     -Name "1.test.innov.website" `
# #     -WebApp $Site `
# #     -SslState SniEnabled `1
# #     -CertificateFilePath "C:\Users\oleh.klymchuk\Downloads\*.test.innov.website.pfx" `
# #     -CertificatePassword 'password' 
# # #-ResourceGroupName $Resource_Group_Name `

# $binding1 = (Get-AzWebAppSSLBinding  -ResourceGroupName $Resource_Group_Name -WebAppName "innotest1")
# $binding1


# $binding = (Get-AzWebAppSSLBinding  -ResourceGroupName $Resource_Group_Name -WebAppName "innotest2")
# $binding.Count


# if ($binding -eq $null) {
#     Write-Host "true"
# }