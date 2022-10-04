#Force TLS 1.2 for now since it doesn't seem to be used by default
param(
     [Parameter()]
     [string]$http_RequestUrl,
 
     [Parameter()]
     [int]$http_RequestRetries,

     [Parameter()]
     [int]$http_RequestTimeout,

     [Parameter()]
     [int]$http_RetrySeconds
 )

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$_Url = $http_RequestUrl
$_Retries = $http_RequestRetries #default: 100
$_Timeout = $http_RequestTimeout #default: 10000
$_RetrySeconds = $http_RetrySeconds #default: 30
#Start count at 1 for output purposes
Write-Host "Waiting for $_RetrySeconds seconds..."
$_Count = 1 
$_StatusCode = 0
$_ErrorResponseContent = ""
while($_Count -le $_Retries) {
    Write-Host "Waiting for $_RetrySeconds seconds..."
    Start-Sleep -s $_RetrySeconds
    Write-Host "" #new line
    try {
        Write-Host "Create web request to $_Url (Attempt $_Count / $_Retries; Timeout: $_Timeout ms)"
        $_Request = [System.Net.WebRequest]::Create($_Url)
        $_Request.Timeout = $_Timeout
        
        $_Response = $_Request.GetResponse()
        #Need to convert the enum code into an int
        $_StatusCode = [int]($_Response.StatusCode)
        $_Response.Close()
    }
    catch [System.Net.WebException] {
        #$_.Exception.Response | Get-Member | Out-Host
        $_ExceptionReponse = $_.Exception.Response
        #Need to convert the enum code into an int
        $_StatusCode = [int]($_ExceptionReponse.StatusCode)
        #Try to get response content
        [System.IO.StreamReader]$_Reader
        $_ErrorResponseContent = ""
        try {
            $_Reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $_ExceptionReponse.GetResponseStream()
            $_FailedResponseContent = $_Reader.ReadToEnd();
            $_ErrorResponseContent = $_FailedResponseContent
            $_Reader.Close()
            $_Reader.Dispose()
        }
        catch {
            #Only update the response content if the string is still empty
            if([string]::IsNullOrEmpty($_ErrorResponseContent)) {
                $_ErrorResponseContent = "Not Available"
            }
        }
    }
    catch {
        throw; #$_StatusCode = [int]$_Response.StatusCode
    }
    Write-Host "Server returned HTTP code $_StatusCode."
    switch ($_StatusCode) {
        ## Success code!
        200 {
            Write-Host "Success!" -ForegroundColor Green 
            $_Count = $_Retries #Setting these equal will break the loop
break
         }
        
        ## Failure special cases
        -1 { Write-Host "Server did not respond or is not reachable..."
break }
        
        500 { 
            Write-Host "::::::::::::::::::::::Response Content::::::::::::::::::::::"
            Write-Host "$_ErrorResponseContent"
break
        }
        default {break }
    }
    $_Count++
}
if(!($_StatusCode -eq 200)) {
    Write-Error "Web request to $_Url did not return a successful HTTP code within $_Retries tries."
}