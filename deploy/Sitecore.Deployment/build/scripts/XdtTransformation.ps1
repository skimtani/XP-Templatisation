param(
    [Parameter(Mandatory=$true)]
    [string] $webAppType,
    [Parameter(Mandatory=$true)]
    [string] $resourceGroupName,
    [Parameter(Mandatory=$true)]
    [string] $webAppName
)
Write-Host "ResourceGroupName: $resourceGroupName - WebAppName: $webAppName" 

$commandBody = @{
    command = "powershell -command `"Import-Module D:\home\Scripts\Update-XmlDocTransform.psm1; Update-XmlDocTransform -xml D:\home\site\wwwroot\web.config -xdt D:\home\site\wwwroot\web.cd.config.xdt`"" 
}

function Get-AzureRmWebAppPublishingCredentials($resourceGroupName, $webAppName, $slotName = $null){
    if ([string]::IsNullOrWhiteSpace($slotName)){
        $resourceType = "Microsoft.Web/sites/config"
        $resourceName = "$webAppName/publishingcredentials"
    }
    else{
        $resourceType = "Microsoft.Web/sites/slots/config"
        $resourceName = "$webAppName/$slotName/publishingcredentials"
    }
    $publishingCredentials = Invoke-AzResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force
    return $publishingCredentials
} 

function Get-KuduApiAuthorizationHeaderValue($resourceGroupName, $webAppName, $slotName = $null){
    $publishingCredentials = Get-AzureRmWebAppPublishingCredentials $resourceGroupName $webAppName $slotName
    return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword))))
} 

function Configure-EnvironmentWebConfig($resourceGroupName, $webAppName, $slotName = "", $webAppType){
    Write-Output "Configuring Web.config for: $webAppType"

    $kuduApiAuthorizationToken = Get-KuduApiAuthorizationHeaderValue $resourceGroupName $webAppName $slotName

    if ([string]::IsNullOrWhiteSpace($slotName)){
        $kuduApiUrl = "https://$webAppName.scm.azurewebsites.net/api/command"
    }
    else{
        $kuduApiUrl = "https://$webAppName`-$slotName.scm.azurewebsites.net/api/command"
    }

    Invoke-RestMethod -Uri $kuduApiUrl `
                        -Headers @{"Authorization"=$kuduApiAuthorizationToken;"If-Match"="*"} `
                        -Method POST `
                        -ContentType "application/json" `
                        -Body (ConvertTo-Json $commandBody)
                        #| Out-Null
}

 

Configure-EnvironmentWebConfig -resourceGroupName $resourceGroupName -webAppName $webAppName -slotName "" -webAppType $webAppType