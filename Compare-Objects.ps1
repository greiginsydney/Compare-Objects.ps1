<#  
.SYNOPSIS  
Feed this script two object names and their type and it will detail the differences between them.

.DESCRIPTION  
Feed this script two object names and their type and it will detail the differences between them. It will run a PowerShell query to 
retrieve the two objects and then output those attributes where they differ.



.NOTES  
    Version				: 1.1
	Date				: 20th May 2018
	Author    			: Greig Sheridan
	
	Revision History 	:
			v1.1: 20th May 2018
                When queried, the PowerShell ISE reports the screen width is 0. Script now checks for zero and forces width to 80
				Added override switch '-width' for extra user control. I assume this is only ever going to be needed by die-hard ISE users ;-)
				Allowed the script to accept a -type of $null so the user can pass in entire objects to be compared, rather than just strings (see examples)
				Added a 'select-object' to only compare the FIRST instance if what's passed in/returned is an array of more than 1 object, and displays a warning
				Added pipeline handling so you can pipe objects to the script (run get-help -full)
				
			v1.0: 5th May 2018
				Initial release. Based on 'Compare-PkiCertificates' : https://greiginsydney.com/compare-pkicertificates-ps1/

.LINK  
    https://greiginsydney.com/Compare-Objects.ps1

.EXAMPLE
	.\Compare-Objects.ps1
 
	Description
	-----------
	With no input parameters passed to it, the script will prompt you to enter the minimum 3 required parameters: a type and two object identities


.EXAMPLE
	.\Compare-Objects.ps1 -Type CsClientPolicy -Object1 'Tag:DownloadABS' -Object2 'Site:Sydney-AU'
 
	Description
	-----------
	Compares the two policies/objects on-screen
	
.EXAMPLE
	.\Compare-Objects.ps1 -Type CsClientPolicy Tag:DownloadABS Site:Sydney-AU
 
	Description
	-----------
	Compares the two policies/objects on-screen. You do not need quotation marks around the object names unless they contain spaces, nor even to specify '-Object1', etc
	
.EXAMPLE
	.\Compare-Objects.ps1 -Type Disk 0 1
 
	Description
	-----------
	It is assumed that the next values provided after the type are the objects in question. The above example works!


.EXAMPLE
	.\Compare-Objects.ps1 -Type Disk 0 1 -width 132
 
	Description
	-----------
	Specify a width to override the automatic screen-width detection. (You'll probably only ever need this when running in the PowerShell ISE)
	
.EXAMPLE
	.\Compare-Objects.ps1 -Type $null $AnObject $AnotherObject
 
	Description
	-----------
	If the -Type specified is null or empty string the script skips the "get-" step and compares the two objects that were passed
	
.EXAMPLE
	[pscustomobject]@{type = 'disk'; object1 = '0'; object2 = '1'} | .\Compare-Objects.ps1
 
	Description
	-----------
	The script accepts pipelined input
	
.EXAMPLE
	[pscustomobject]@{type = $null; object1 = $greig; object2 = $jess; SkipUpdateCheck = $True} | .\Compare-Objects.ps1
 
	Description
	-----------
	The script will accept two objects via the pipeline and compare them. Don't forget to add the "SkipUpdateCheck" if you're pipelining	
	
	
.PARAMETER Type
	String. Enter the object type of the items to be compared. The script will execute a "Get-<Type>" command to query the two objects named next, then compare the results.
	Enter a Type of $null or "" if you're already passing in the Objects to be compared (as distinct from just their names to be queried)
	
.PARAMETER Object1
	Object. Can be either a string (the name of an object to be queried, to be used with a -Type), or an object of any type if you've already captured it into a variable
		
.PARAMETER Object2
	Object. As above

.PARAMETER Width
	Integer. If you're running in the PowerShell ISE it doesn't report the screen's width. This parameter lets you set/constrain the width used by the script
	
.PARAMETER SkipUpdateCheck
	Boolean. Skips the automatic check for an Update. Courtesy of Pat: http://www.ucunleashed.com/3168

#>

[CmdletBinding(SupportsShouldProcess = $False)]
Param(
	
	[Parameter(Mandatory = $True,Position=1, ValueFromPipelineByPropertyName = $true)]
	[AllowEmptyString()]
	[String]$Type,
	
    [Parameter(Mandatory = $True,Position=2, ValueFromPipelineByPropertyName = $true)]
	[ValidateNotNullOrEmpty()]
	[alias('Obj1')][object]$Object1,
	
	[Parameter(Mandatory = $True,Position=3, ValueFromPipelineByPropertyName = $true)]
	[ValidateNotNullOrEmpty()]
	[alias('Obj2')][object]$Object2,
	
	[Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $true)]
	[ValidateRange(40,1000)]
	[int]$Width,
	
	[Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $true)]
	[switch] $SkipUpdateCheck
)
      

#--------------------------------
# START FUNCTIONS ---------------
#--------------------------------

function Get-UpdateInfo
{
  <#
      .SYNOPSIS
      Queries an online XML source for version information to determine if a new version of the script is available.
	  *** This version customised by Greig Sheridan. @greiginsydney https://greiginsydney.com ***

      .DESCRIPTION
      Queries an online XML source for version information to determine if a new version of the script is available.

      .NOTES
      Version               : 1.2 - See changelog at https://ucunleashed.com/3168 for fixes & changes introduced with each version
      Wish list             : Better error trapping
      Rights Required       : N/A
      Sched Task Required   : No
      Lync/Skype4B Version  : N/A
      Author/Copyright      : © Pat Richard, Office Servers and Services (Skype for Business) MVP - All Rights Reserved
      Email/Blog/Twitter    : pat@innervation.com  https://ucunleashed.com  @patrichard
      Donations             : https://www.paypal.me/PatRichard
      Dedicated Post        : https://ucunleashed.com/3168
      Disclaimer            : You running this script/function means you will not blame the author(s) if this breaks your stuff. This script/function 
                            is provided AS IS without warranty of any kind. Author(s) disclaim all implied warranties including, without limitation, 
                            any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use 
                            or performance of the sample scripts and documentation remains with you. In no event shall author(s) be held liable for 
                            any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss 
                            of business information, or other pecuniary loss) arising out of the use of or inability to use the script or 
                            documentation. Neither this script/function, nor any part of it other than those parts that are explicitly copied from 
                            others, may be republished without author(s) express written permission. Author(s) retain the right to alter this 
                            disclaimer at any time. For the most up to date version of the disclaimer, see https://ucunleashed.com/code-disclaimer.
      Acknowledgements      : Reading XML files 
                            http://stackoverflow.com/questions/18509358/how-to-read-xml-in-powershell
                            http://stackoverflow.com/questions/20433932/determine-xml-node-exists
      Assumptions           : ExecutionPolicy of AllSigned (recommended), RemoteSigned, or Unrestricted (not recommended)
      Limitations           : 
      Known issues          : 

      .EXAMPLE
      Get-UpdateInfo -Title 'Compare-Objects.ps1'

      Description
      -----------
      Runs function to check for updates to script called 'Compare-Objects.ps1'.

      .INPUTS
      None. You cannot pipe objects to this script.
  #>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
	[string] $title
	)
	try
	{
		[bool] $HasInternetAccess = ([Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}')).IsConnectedToInternet)
		if ($HasInternetAccess)
		{
			write-verbose -message 'Performing update check'
			# ------------------ TLS 1.2 fixup from https://github.com/chocolatey/choco/wiki/Installation#installing-with-restricted-tls
			$securityProtocolSettingsOriginal = [Net.ServicePointManager]::SecurityProtocol
			try {
			  # Set TLS 1.2 (3072). Use integers because the enumeration values for TLS 1.2 won't exist in .NET 4.0, even though they are 
			  # addressable if .NET 4.5+ is installed (.NET 4.5 is an in-place upgrade).
			  [Net.ServicePointManager]::SecurityProtocol = 3072
			} catch {
			  write-verbose -message 'Unable to set PowerShell to use TLS 1.2 due to old .NET Framework installed.'
			}
			# ------------------ end TLS 1.2 fixup
			[xml] $xml = (New-Object -TypeName System.Net.WebClient).DownloadString('https://greiginsydney.com/wp-content/version.xml')
			[Net.ServicePointManager]::SecurityProtocol = $securityProtocolSettingsOriginal #Reinstate original SecurityProtocol settings
			$article  = select-XML -xml $xml -xpath ("//article[@title='{0}']" -f ($title))
			[string] $Ga = $article.node.version.trim()
			if ($article.node.changeLog)
			{
				[string] $changelog = 'This version includes: ' + $article.node.changeLog.trim() + "`n`n"
			}
			if ($Ga -gt $ScriptVersion)
			{
				$wshell = New-Object -ComObject Wscript.Shell -ErrorAction Stop
				$updatePrompt = $wshell.Popup(("Version {0} is available.`n`n{1}Would you like to download it?" -f ($ga), ($changelog)),0,'New version available',68)
				if ($updatePrompt -eq 6)
				{
					Start-Process -FilePath $article.node.downloadUrl
					write-warning -message "Script is exiting. Please run the new version of the script after you've downloaded it."
					exit
				}
				else
				{
					write-verbose -message ('Upgrade to version {0} was declined' -f ($ga))
				}
			}
			elseif ($Ga -eq $ScriptVersion)
			{
				write-verbose -message ('Script version {0} is the latest released version' -f ($Scriptversion))
			}
			else
			{
				write-verbose -message ('Script version {0} is newer than the latest released version {1}' -f ($Scriptversion), ($ga))
			}
		}
		else
		{
		}
	
	} # end function Get-UpdateInfo
	catch
	{
		write-verbose -message 'Caught error in Get-UpdateInfo'
		if ($Global:Debug)
		{				
			$Global:error | Format-List -Property * -Force #This dumps to screen as white for the time being. I haven't been able to get it to dump in red
		}
	}
}


function query-object
{
	param ( [string] $type, [string] $Object)

	write-progress -id 1 -Activity 'Querying' -Status "$Type -identity ""$Object""" -PercentComplete 0
	$return = invoke-expression "$Type ""$Object"" -verbose:`$false -erroraction silentlycontinue -warningaction silentlycontinue"
	write-progress -id 1 -Activity 'Querying' -Status "$ObjectType -identity ""$Object""" -Complete
	return $return
}


function cleanup-object
{
	param ([object]$toClean)
	[string]$Cleaned = ''
	
	if ($toClean -ne $null)
	{
		foreach ($item in $toClean)
		{
			$Cleaned += $item
		}
	}
	$Cleaned = [regex]::replace($Cleaned, '\n' , ' ') # Strip any CR's - they'll break the output format.
	return $Cleaned
}


function DisplayDifferences
{
	param (
	[Parameter(Mandatory=$True)][string]$parameterName,
	[Parameter(Mandatory=$False)][string]$Object1Value = '',
	[Parameter(Mandatory=$False)][string]$Object2Value = ''
	)

	$parameterName =  truncate $parameterName ($global:HeaderWidth)
	$Object1Value =  truncate $Object1Value ($global:ColumnWidth)
	$Object2Value =  truncate $Object2Value ($global:ColumnWidth)
	write-host ($parameterName).PadRight($global:HeaderWidth,' ') -noNewLine 
	write-host ' ' -NoNewLine
	write-host ($Object1Value).PadRight($global:ColumnWidth,' ') -noNewLine 
	write-host ' ' -NoNewLine
	write-host ($Object2Value).PadRight($global:ColumnWidth,' ')
}


function truncate
{
	param ([string]$value, [int]$MaxLength)
	
	if ($MaxLength -gt 0) { $MaxLength-- }
	if ($value.Length -gt $MaxLength)
	{
		$value = $value[0..($MaxLength - 3)] -join ''
		$value += '...'
	}
	return $value
}

function Set-Label
{
	param ([object]$passedObject, [string]$WhichOne)
	If ($passedObject.GetType().Name -eq 'String')
	{
		return $passedObject
	}
	else
	{
		return "Object{0}" -f $WhichOne
	}
}

function TestFor-Array
{
	param ([object]$PassedObject, [string] $ObjectLabel)

	if ($PassedObject.Count -gt 1)
	{
		write-warning """$($ObjectLabel)"" contains more than one object. Only the first is compared"
	}
	return  $PassedObject  | select-object -first 1	# Just in case there are more than 1 in there

}

#--------------------------------
# END  FUNCTIONS ---------------
#--------------------------------


#--------------------------------
# THE FUN STARTS HERE -----------
#--------------------------------

$ScriptVersion = '1.1' 
$Error.Clear()   
$Global:Debug = $psboundparameters.debug.ispresent
$UserScreenWidth = [int](get-host).UI.rawui.Windowsize.Width
if ($PSBoundParameters.ContainsKey('Width')) {$UserScreenWidth = $width }
if ($UserScreenWidth -eq 0)
{
	write-warning "Powershell ISE detected. Screen width fixed to 80. Go wider by adding a ""-width"" parameter"
    $UserScreenWidth = 80 #Curse you ISE!
}
$global:HeaderWidth = ([Math]::Truncate($UserScreenWidth * 0.2) -1) 
$global:ColumnWidth = ([Math]::Truncate($UserScreenWidth * 0.4) -1) 
$DifferenceCount = 0

if ($skipupdatecheck)
{
	write-verbose -message 'Skipping update check'
}
else
{
	write-progress -id 1 -Activity 'Initialising' -Status 'Performing update check' -PercentComplete (0)
	Get-UpdateInfo -title 'Compare-Objects.ps1'
	write-progress -id 1 -Activity 'Initialising' -Status 'Back from performing update check' -Complete
}

#Do I need to query the objects or did the user do the hard work already and I only need to compare them?
if ($Type -ne '')
{
	if (!($Type.StartsWith('Get-','CurrentCultureIgnoreCase')))
	{
		$Type = 'Get-' + $Type
	}
	$FirstObject  = query-object -type $Type -object $Object1
	$SecondObject = query-object -type $Type -object $Object2
}
else
{
	$FirstObject  = $Object1
	$SecondObject = $Object2
}

# This code's required for the column headings of the two objects. Try as I might, if you pass an object in, I couldn't
# find a way of accessing its name. It appears to be discarded and the object it represents is passed in - and because of that 
# flexibility I can't be sure it has a '.Name' property to use as the column heading - so I've gone with just 'Object1' and 'Object2'
$Object1Label = Set-Label $Object1 "1"
$Object2Label = Set-Label $Object2 "2"

$FirstObject  = TestFor-Array $FirstObject  $Object1Label
$SecondObject = TestFor-Array $SecondObject $Object2Label

if (($FirstObject -ne $null) -and ($SecondObject -ne $null))
{
	#Read all the properties of BOTH objects & then de-dupe. This will trap any that are present on one but not the other:
	$properties  = ($FirstObject  | Get-Member -MemberType Property,NoteProperty | Select-Object -ExpandProperty Name)
	$properties += ($SecondObject | Get-Member -MemberType Property,NoteProperty | Select-Object -ExpandProperty Name)
	$properties  = $properties  | select -uniq	
	write-verbose "$($Type) has $($properties.count) attributes"
	write-host ''
	write-host  'Attribute'.PadRight($HeaderWidth, ' ')($Object1Label).PadRight($ColumnWidth, ' ')($Object2Label).PadRight($ColumnWidth, ' ')
	write-host  ('---------').PadRight($HeaderWidth, ' ')('-------------').PadRight($ColumnWidth, ' ')('-------------').PadRight($ColumnWidth, ' ')
	
	foreach ($property in $properties)
	{
		switch ($property)
		{
			'Identity' 	#Already output as the header in the table
			{ continue }
			'Anchor' 	#They'll ALWAYS have a different anchor value, which is irrelevant
			{ continue }
			'Element' 	# 'Element' is the whole object as one attribute (of itself!), so it's pointless displaying this - & as above, they'll always differ
			{ continue }
			default	
			{
				try
				{
					if ($FirstObject.$property -ne $SecondObject.$property)
					{
						$value1 = cleanup-object $FirstObject.$property
						$value2 = cleanup-object $SecondObject.$property
						#Re-test for difference, in case after cleanup the values now equate
						if ($value1 -ne $value2)
						{
							DisplayDifferences $property $value1 $value2
							$DifferenceCount ++
						}
					}
				}
				catch
				{
					write-warning "Value ""$($property)"" threw an error"
					if ($Global:Debug)
					{				
						$Global:error | fl * -f 
					}
				}
			}
		}
	}
	write-host # A separator
	switch ($DifferenceCount)
	{
		0  		{ write-host 'The two objects are essentially identical' }
		1  		{ write-verbose 'Only 1 attribute differs' }
		default { write-verbose "$($DifferenceCount) attributes have different values" }
	}
	write-host # A blank line at the end
}
else
{
	if ($FirstObject  -eq $null) { write-warning "The object ""$Object1"" could not be found" }
	if ($SecondObject -eq $null) { write-warning "The object ""$Object2"" could not be found" }
}


#References:
# Detecting / Handling ISE:
# https://stackoverflow.com/questions/44871264/how-can-i-measure-the-window-height-number-of-lines-in-powershell
# Validate range: https://learn-powershell.net/2014/02/04/using-powershell-parameter-validation-to-make-your-day-easier/

#Code signing certificate kindly provided by Digicert:
# SIG # Begin signature block
# MIIceAYJKoZIhvcNAQcCoIIcaTCCHGUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7hVxN45xCT3vF2QraJPbzHFN
# q7igghenMIIFMDCCBBigAwIBAgIQA1GDBusaADXxu0naTkLwYTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMDQxNzAwMDAwMFoXDTIxMDcw
# MTEyMDAwMFowbTELMAkGA1UEBhMCQVUxGDAWBgNVBAgTD05ldyBTb3V0aCBXYWxl
# czESMBAGA1UEBxMJUGV0ZXJzaGFtMRcwFQYDVQQKEw5HcmVpZyBTaGVyaWRhbjEX
# MBUGA1UEAxMOR3JlaWcgU2hlcmlkYW4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
# ggEKAoIBAQC0PMhHbI+fkQcYFNzZHgVAuyE3BErOYAVBsCjZgWFMhqvhEq08El/W
# PNdtlcOaTPMdyEibyJY8ZZTOepPVjtHGFPI08z5F6BkAmyJ7eFpR9EyCd6JRJZ9R
# ibq3e2mfqnv2wB0rOmRjnIX6XW6dMdfs/iFaSK4pJAqejme5Lcboea4ZJDCoWOK7
# bUWkoqlY+CazC/Cb48ZguPzacF5qHoDjmpeVS4/mRB4frPj56OvKns4Nf7gOZpQS
# 956BgagHr92iy3GkExAdr9ys5cDsTA49GwSabwpwDcgobJ+cYeBc1tGElWHVOx0F
# 24wBBfcDG8KL78bpqOzXhlsyDkOXKM21AgMBAAGjggHFMIIBwTAfBgNVHSMEGDAW
# gBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAdBgNVHQ4EFgQUzBwyYxT+LFH+GuVtHo2S
# mSHS/N0wDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGA1Ud
# HwRwMG4wNaAzoDGGL2h0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3Vy
# ZWQtY3MtZzEuY3JsMDWgM6Axhi9odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hh
# Mi1hc3N1cmVkLWNzLWcxLmNybDBMBgNVHSAERTBDMDcGCWCGSAGG/WwDATAqMCgG
# CCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAgGBmeBDAEE
# ATCBhAYIKwYBBQUHAQEEeDB2MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wTgYIKwYBBQUHMAKGQmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydFNIQTJBc3N1cmVkSURDb2RlU2lnbmluZ0NBLmNydDAMBgNVHRMB
# Af8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQCtV/Nu/2vgu+rHGFI6gssYWfYLEwXO
# eJqOYcYYjb7dk5sRTninaUpKt4WPuFo9OroNOrw6bhvPKdzYArXLCGbnvi40LaJI
# AOr9+V/+rmVrHXcYxQiWLwKI5NKnzxB2sJzM0vpSzlj1+fa5kCnpKY6qeuv7QUCZ
# 1+tHunxKW2oF+mBD1MV2S4+Qgl4pT9q2ygh9DO5TPxC91lbuT5p1/flI/3dHBJd+
# KZ9vYGdsJO5vS4MscsCYTrRXvgvj0wl+Nwumowu4O0ROqLRdxCZ+1X6a5zNdrk4w
# Dbdznv3E3s3My8Axuaea4WHulgAvPosFrB44e/VHDraIcNCx/GBKNYs8MIIFMDCC
# BBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0Ew
# HhcNMTMxMDIyMTIwMDAwWhcNMjgxMDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5n
# IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfT
# CzFJGc/Q+0WZsTrbRPV/5aid2zLXcep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdgl
# rA55KDp+6dFn08b7KSfH03sjlOSRI5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRn
# iolF1C2ho+mILCCVrhxKhwjfDPXiTWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7
# MRzP6vIK5Fe7SrXpdOYr/mzLfnQ5Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPr
# CGQ+UpbB8g8S9MWOD8Gi6CxR93O8vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z
# 3yWT0QIDAQABo4IBzTCCAckwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8E
# BAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsG
# AQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0
# dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0g
# BEgwRjA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRp
# Z2ljZXJ0LmNvbS9DUFMwCgYIYIZIAYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nED
# wGD5LfZldQ5YMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqG
# SIb3DQEBCwUAA4IBAQA+7A1aJLPzItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9
# D8Svi/3vKt8gVTew4fbRknUPUbRupY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQG
# ivecRk5c/5CxGwcOkRX7uq+1UcKNJK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEeh
# emhor5unXCBc2XGxDI+7qPjFEmifz0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJ
# RZboWR3p+nRka7LrZkPas7CM1ekN3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5
# gkn3Ym6hU/oSlBiFLpKR6mhsRDKyZqHnGKSaZFHvMIIGajCCBVKgAwIBAgIQAwGa
# Ajr/WLFr1tXq5hfwZjANBgkqhkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEw
# HwYDVQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTEwHhcNMTQxMDIyMDAwMDAw
# WhcNMjQxMDIyMDAwMDAwWjBHMQswCQYDVQQGEwJVUzERMA8GA1UEChMIRGlnaUNl
# cnQxJTAjBgNVBAMTHERpZ2lDZXJ0IFRpbWVzdGFtcCBSZXNwb25kZXIwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCjZF38fLPggjXg4PbGKuZJdTvMbuBT
# qZ8fZFnmfGt/a4ydVfiS457VWmNbAklQ2YPOb2bu3cuF6V+l+dSHdIhEOxnJ5fWR
# n8YUOawk6qhLLJGJzF4o9GS2ULf1ErNzlgpno75hn67z/RJ4dQ6mWxT9RSOOhkRV
# fRiGBYxVh3lIRvfKDo2n3k5f4qi2LVkCYYhhchhoubh87ubnNC8xd4EwH7s2AY3v
# J+P3mvBMMWSN4+v6GYeofs/sjAw2W3rBerh4x8kGLkYQyI3oBGDbvHN0+k7Y/qpA
# 8bLOcEaD6dpAoVk62RUJV5lWMJPzyWHM0AjMa+xiQpGsAsDvpPCJEY93AgMBAAGj
# ggM1MIIDMTAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8E
# DDAKBggrBgEFBQcDCDCCAb8GA1UdIASCAbYwggGyMIIBoQYJYIZIAYb9bAcBMIIB
# kjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCCAWQG
# CCsGAQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMA
# IABDAGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMA
# IABhAGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMA
# ZQByAHQAIABDAFAALwBDAFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkA
# bgBnACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgA
# IABsAGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUA
# IABpAG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAA
# cgBlAGYAZQByAGUAbgBjAGUALjALBglghkgBhv1sAxUwHwYDVR0jBBgwFoAUFQAS
# KxOYspkH7R7for5XDStnAs0wHQYDVR0OBBYEFGFaTSS2STKdSip5GoNL9B6Jwcp9
# MH0GA1UdHwR2MHQwOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydEFzc3VyZWRJRENBLTEuY3JsMDigNqA0hjJodHRwOi8vY3JsNC5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRBc3N1cmVkSURDQS0xLmNybDB3BggrBgEFBQcBAQRrMGkw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcw
# AoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElE
# Q0EtMS5jcnQwDQYJKoZIhvcNAQEFBQADggEBAJ0lfhszTbImgVybhs4jIA+Ah+WI
# //+x1GosMe06FxlxF82pG7xaFjkAneNshORaQPveBgGMN/qbsZ0kfv4gpFetW7ea
# sGAm6mlXIV00Lx9xsIOUGQVrNZAQoHuXx/Y/5+IRQaa9YtnwJz04HShvOlIJ8Oxw
# YtNiS7Dgc6aSwNOOMdgv420XEwbu5AO2FKvzj0OncZ0h3RTKFV2SQdr5D4HRmXQN
# JsQOfxu19aDxxncGKBXp2JPlVRbwuwqrHNtcSCdmyKOLChzlldquxC5ZoGHd2vNt
# omHpigtt7BIYvfdVVEADkitrwlHCCkivsNRu4PQUCjob4489yq9qjXvc2EQwggbN
# MIIFtaADAgECAhAG/fkDlgOt6gAK6z8nu7obMA0GCSqGSIb3DQEBBQUAMGUxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBD
# QTAeFw0wNjExMTAwMDAwMDBaFw0yMTExMTAwMDAwMDBaMGIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAOiCLZn5ysJClaWAc0Bw0p5WVFypxNJBBo/J
# M/xNRZFcgZ/tLJz4FlnfnrUkFcKYubR3SdyJxArar8tea+2tsHEx6886QAxGTZPs
# i3o2CAOrDDT+GEmC/sfHMUiAfB6iD5IOUMnGh+s2P9gww/+m9/uizW9zI/6sVgWQ
# 8DIhFonGcIj5BZd9o8dD3QLoOz3tsUGj7T++25VIxO4es/K8DCuZ0MZdEkKB4YNu
# gnM/JksUkK5ZZgrEjb7SzgaurYRvSISbT0C58Uzyr5j79s5AXVz2qPEvr+yJIvJr
# GGWxwXOt1/HYzx4KdFxCuGh+t9V3CidWfA9ipD8yFGCV/QcEogkCAwEAAaOCA3ow
# ggN2MA4GA1UdDwEB/wQEAwIBhjA7BgNVHSUENDAyBggrBgEFBQcDAQYIKwYBBQUH
# AwIGCCsGAQUFBwMDBggrBgEFBQcDBAYIKwYBBQUHAwgwggHSBgNVHSAEggHJMIIB
# xTCCAbQGCmCGSAGG/WwAAQQwggGkMDoGCCsGAQUFBwIBFi5odHRwOi8vd3d3LmRp
# Z2ljZXJ0LmNvbS9zc2wtY3BzLXJlcG9zaXRvcnkuaHRtMIIBZAYIKwYBBQUHAgIw
# ggFWHoIBUgBBAG4AeQAgAHUAcwBlACAAbwBmACAAdABoAGkAcwAgAEMAZQByAHQA
# aQBmAGkAYwBhAHQAZQAgAGMAbwBuAHMAdABpAHQAdQB0AGUAcwAgAGEAYwBjAGUA
# cAB0AGEAbgBjAGUAIABvAGYAIAB0AGgAZQAgAEQAaQBnAGkAQwBlAHIAdAAgAEMA
# UAAvAEMAUABTACAAYQBuAGQAIAB0AGgAZQAgAFIAZQBsAHkAaQBuAGcAIABQAGEA
# cgB0AHkAIABBAGcAcgBlAGUAbQBlAG4AdAAgAHcAaABpAGMAaAAgAGwAaQBtAGkA
# dAAgAGwAaQBhAGIAaQBsAGkAdAB5ACAAYQBuAGQAIABhAHIAZQAgAGkAbgBjAG8A
# cgBwAG8AcgBhAHQAZQBkACAAaABlAHIAZQBpAG4AIABiAHkAIAByAGUAZgBlAHIA
# ZQBuAGMAZQAuMAsGCWCGSAGG/WwDFTASBgNVHRMBAf8ECDAGAQH/AgEAMHkGCCsG
# AQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29t
# MEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNl
# cnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqg
# OKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURS
# b290Q0EuY3JsMB0GA1UdDgQWBBQVABIrE5iymQftHt+ivlcNK2cCzTAfBgNVHSME
# GDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEARlA+
# ybcoJKc4HbZbKa9Sz1LpMUerVlx71Q0LQbPv7HUfdDjyslxhopyVw1Dkgrkj0bo6
# hnKtOHisdV0XFzRyR4WUVtHruzaEd8wkpfMEGVWp5+Pnq2LN+4stkMLA0rWUvV5P
# sQXSDj0aqRRbpoYxYqioM+SbOafE9c4deHaUJXPkKqvPnHZL7V/CSxbkS3BMAIke
# /MV5vEwSV/5f4R68Al2o/vsHOE8Nxl2RuQ9nRc3Wg+3nkg2NsWmMT/tZ4CMP0qqu
# AHzunEIOz5HXJ7cW7g/DvXwKoO4sCFWFIrjrGBpN/CohrUkxg0eVd3HcsRtLSxwQ
# nHcUwZ1PL1qVCCkQJjGCBDswggQ3AgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAv
# BgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EC
# EANRgwbrGgA18btJ2k5C8GEwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDCvNug5ivfFyYxNuGNQ
# Hrdu1OpiMA0GCSqGSIb3DQEBAQUABIIBAJjv4yPRr5iipNirWb2biOzQW4cfSklE
# xafhYwn7Kjkns8X1vLsWlTUnM2uVyMQJV0Z5ugsXkib5kBka1LUG8d+S0VklMxOo
# +ZFWS9XQwqgiJm8zaPYLk/rBA9FeuM5xH/XjqZOa1kMWUv2+7QBkmcsypj6rpV0/
# ce8CkE57qUcnmlh2f2BKW9TITikyGUIYRtpzhAOQWk3dBQYaCjnHraJpcJRZz9PF
# 4jbwTbk2t4uIqrH8BroegzF8I5rrkpxtW5TMj7wKITim/OBAAljR/38ovAzB7UI4
# uC+FcNCTFbZwBKFdJOzmWZNgAKYFC/gVJKXAsBLU2kntwEGSjZVrJAehggIPMIIC
# CwYJKoZIhvcNAQkGMYIB/DCCAfgCAQEwdjBiMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYD
# VQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTECEAMBmgI6/1ixa9bV6uYX8GYw
# CQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcN
# AQkFMQ8XDTIwMDUwNTExMjYyN1owIwYJKoZIhvcNAQkEMRYEFO1sPPzM+kjzcZF2
# LlCq7s8c1geYMA0GCSqGSIb3DQEBAQUABIIBACHI3OTdyPFb+bMTsDswhebxsu6m
# fYZDgEiHnVGjePpEfA1kFyNn4GHEpwAXKpThMzDCZcYRh9DMlAIxCZiUmCFq67UW
# hzJRNf1Gss5rk1o7qsIkS4gEvkI4wHcgARSSNH/75sR+FWZxFBD50mXLajNhOgZE
# 916aq6pWoo/ZbANGJ/sqqwe45qMss5sNzO91v/vMQ8Byw2MbublGGASKIEckMXSH
# Y6xi43ep+c90ASV9zbCigmerR/BHCvKBBZ9+RVrv08Oh7WTR0ySCZPw6uLfKTMKf
# FMzf1Ue0b8bds3hkyj8dHPzE69T7YQr70dG3fZFIc2lDnYq4xuJBGDo9wkU=
# SIG # End signature block
