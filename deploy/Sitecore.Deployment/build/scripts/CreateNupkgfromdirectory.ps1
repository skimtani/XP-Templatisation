Param(
    [Parameter(Mandatory=$true)]
    [string] $PackageName,

    [Parameter(Mandatory=$true)]
    [string] $OutputDirectory,

    [Parameter(Mandatory=$false)]
    [string] $InputDirectory,

	[Parameter(Mandatory=$false)]
    [string] $Version
)

$ErrorActionPreference = "Stop"

function Create-VersionFromDate() {
    $version = $([System.DateTime]::Now.ToString("yyyy.M.d.hhmm"))
    Write-Host "Version: $version"
    return $version
}

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

#Create a new nuspec file
Write-Host "Creating a single nuspec file for all projects."
Create-NuSpecFile $InputDirectory -Name $PackageName -Version $Version

#Write-Host "Deleting web.config file (if it exists)"
#Get-ChildItem $InputDirectory -Filter "web.config" | Remove-Item -Force

#Compress a new zip file with all projects
mkdir $OutputDirectory
Write-Host "Compressing extracted files into a single NuGet package."
Get-ChildItem $InputDirectory | Compress-Archive -DestinationPath "$OutputDirectory\$PackageName.zip"
Get-ChildItem $OutputDirectory -Filter "$PackageName.zip" | Rename-Item -NewName "$PackageName.$version.nupkg"

Write-Host "Done!"