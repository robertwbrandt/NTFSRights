#     Script to export a directories ACLs
#     Bob Brandt <projects@brandt.ie>
#          
#     Copyright (C) 2013 Free Software Foundation, Inc."
#     License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
#     This program is free software: you can redistribute it and/or modify it under
#     the terms of the GNU General Public License as published by the Free Software
#     Foundation, either version 3 of the License, or (at your option) any later
#     version.
#     This program is distributed in the hope that it will be useful, but WITHOUT ANY
#     WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#     PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#




# This function is used to retrieve the ACLs from a file or directory
function getACLs ([string]$path, [bool]$ignoreInherited=$true) {
	if (-not ([System.IO.Directory]::Exists($path) -or [System.IO.File]::Exists($path))) {
		throw "Path (`"$($path)`") doesn't exist."
	} else {
		$pathLen = ($path.ToCharArray() | Where-Object {$_} | Measure-Object).Count + 1
		$cmd = 'icacls "' + $path + '" 2>nul | findstr ":"'
		$output = (cmd /c $cmd)

		$output | ForEach {
			$acl = $_.Substring($pathLen).split(":")
			$sid = $acl[0]
			$acl = $acl[1]
			if (-not (($ignoreInherited) -and (($acl -match '(I)') -or ($acl -match '(OI)') -or ($acl -match '(CI)') -or ($acl -match '(IO)')))) {
				$type = "file"
				if ((Get-Item "$path") -is [System.IO.DirectoryInfo]) {
					$type = "dir"
				}
				Write-Host "`"$type`",`"$path`",`"$sid`",`"$acl`""
			}
		}
	}
}


# This function is used to retrieve all children from a path (Do Not Resurse into path)
function getList ([string]$path, [bool]$ignoreFiles=$true) {
	if (-not ([System.IO.Directory]::Exists($path) -or [System.IO.File]::Exists($path))) {
		throw "Path (`"$($path)`") doesn't exist."
	} else {
		Get-ChildItem "$path" | Sort-Object name | Foreach-Object {
			if ( -not ($_.name.StartsWith('.') -or $_.name.StartsWith('~'))) {
				if ((-not $ignoreFiles) -or $_.PSIsContainer ) {
					$_.fullname
				}
			}
		}
	}
}

# This function is used to process a path - Recursively 
function processDir ([string]$path, [bool]$recursive=$true, [bool]$ignoreFiles=$true, [bool]$ignoreInherited=$true) {
	if (-not ([System.IO.Directory]::Exists($path) -or [System.IO.File]::Exists($path))) {
		throw "Path (`"$($path)`") doesn't exist."
	} else {
		if ($recursive) {
			getList "$path" $ignoreFiles | ForEach {
				if ((Get-Item "$_") -is [System.IO.DirectoryInfo]) {
					processDir "$_" $ignoreFiles $ignoreInherited
				}
				getACLs "$path" $ignoreInherited
			}
		} else {
			getACLs "$path" $ignoreInherited
		}
	}
}




#getACLs "C:\Documents and Settings\brandtb.i" $false
#getACLs "F:\ArtMgt" $true
#getACLs "\\opw-filer01\DublinGroups\ArtMgt" $true
#getACLs "\\opw-filer01\DublinGroups\ArtMgt\Images\art00003.jpg" $false
#getACLs "F:\ArtMgt\Images\art00003.jpg" $false

processDir "G:\icacls" $true $true $false
#processDir "G:\" $true $true
#processDir "F:\ArtMgt"
#getList "F:\ArtMgt\Images\art00003.jpg" $false


