$(get-childitem "$psscriptroot" -Recurse -Include "*.ps1").foreach{. $_.FullName}
#. c:\users\dave\downloads\fudgepack\public\invoke-fudgepack.ps1 
