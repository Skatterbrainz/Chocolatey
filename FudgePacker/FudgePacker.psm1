$(get-childitem "$psscriptroot" -Recurse -Include "*.ps1").foreach{. $_.FullName}
