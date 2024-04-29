#Requires -RunAsAdministrator

If ( $ExecutionContext.SessionState.LanguageMode -eq "ConstrainedLanguage") {

  Set-ItemProperty 'hklm:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -name '__PSLockdownPolicy' -Value 8

  Start-Process -File PowerShell.exe -Argument "-file $($myinvocation.mycommand.definition)"

  Break

}

# ENTER SCRIPT HERE

Write-Host $ExecutionContext.SessionState.LanguageMode

Start-Sleep -s 10