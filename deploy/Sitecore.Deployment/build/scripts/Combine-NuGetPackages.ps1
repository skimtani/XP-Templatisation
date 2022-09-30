Param(
    [Parameter(Mandatory=$true)]
    [string] $PackageName,

    [Parameter(Mandatory=$true)]
    [string] $OutputDirectory,

    [Parameter(Mandatory=$false)]
    [string] $InputDirectory = $OutputDirectory,

	[Parameter(Mandatory=$false)]
    [string] $TempDirectory = "$Directory\Temp",

	[Parameter(Mandatory=$false)]
    [string] $Version
)

$ErrorActionPreference = "Stop"

function Create-VersionFromDate() {
    $version = $([System.DateTime]::Now.ToString("yyyy.M.d.hhmm"))
    Write-Host "Version: $version"
    return $version
}


$ExcludeFiles = New-Object -TypeName System.Collections.Generic.List[string]
$ExcludeFiles.Add("Neptune.Environment.$Version.nupkg")
$ExcludeFiles.Add("Neptune.Deployment.$Version.nupkg")

function Create-NuSpecFile([string] $Path, [string] $Name, [string] $Version) {
    $xmlPath = "$Path\$Name.nuspec"
	Write-Host "Creating nuspec file for NuGet package: $xmlPath"
    $xmlWriter = New-Object System.XMl.XmlTextWriter($xmlPath,$Null)
    $xmlWriter.Formatting = 'Indented'
    $xmlWriter.Indentation = 1
    $xmlWriter.IndentChar = "`t"
    $xmlWriter.WriteStartDocument()

    #create package nodde
    $xmlWriter.WriteStartElement("package","http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd")
    
    #create metadata node
    $xmlWriter.WriteStartElement("metadata");

    #write the required nuspec fields
    $xmlWriter.WriteElementString("id", $Name);
    $xmlWriter.WriteElementString("version", $Version);
    $xmlWriter.WriteElementString("authors", "Horizontal Integration");
    $xmlWriter.WriteElementString("description", "Package that contains the $Name web project files.");

    #close the metadata and package nodes
    $xmlWriter.WriteEndElement();
    $xmlWriter.WriteEndElement();

    #write to file
    $xmlWriter.Close();
}

if([string]::IsNullOrEmpty($Version)) {
	$Version = Create-VersionFromDate
}

#Unpack all archives into the temp folder
Write-Host "Extracting the NuGet packages..."
Get-ChildItem $InputDirectory -Filter "*.nupkg" | Where-Object {!$ExcludeFiles.Contains($_.Name)} | Rename-Item -NewName { "$($_.Name -replace '.nupkg', '.zip')" } -PassThru | Expand-Archive -DestinationPath "$TempDirectory" -Force

#Delete all nuspec files
Write-Host "Deleting the existing nuspec files."
Get-ChildItem $TempDirectory -Filter "*.nuspec" | Remove-Item -Force

Write-Host "Deleting web.config file (if it exists)"
Get-ChildItem $TempDirectory -Filter "web.config" | Remove-Item -Force

#Create a new nuspec file
Write-Host "Creating a single nuspec file for all projects."
Create-NuSpecFile $TempDirectory -Name $PackageName -Version $Version

#Compress a new zip file with all projects
Write-Host "Compressing extracted files into a single NuGet package."
mkdir $OutputDirectory
Get-ChildItem $TempDirectory | Compress-Archive -DestinationPath "$OutputDirectory\$PackageName.zip"
Get-ChildItem $OutputDirectory -Filter "$PackageName.zip" | Rename-Item -NewName "$PackageName.$version.nupkg"

#Move any NuGet packages that weren't packaged into a single project to the publish directory
Write-Host "Moving any NuGet packages that weren't packaged into a single project to the publish directory"
Get-ChildItem -Path "$InputDirectory\*.nupkg" | Move-Item -Destination "$OutputDirectory"

Write-Host "Done!"