$binrequest = Get-ExchangeCertificate -Thumbprint 78014e2648c826d9d9021006c82640dedd6c36b2 | New-ExchangeCertificate -GenerateRequest -BinaryEncoded -KeySize 2048 -Server ATLMSEMMBX04.kesinc.biz
[System.IO.File]::WriteAllBytes('\\10.0.100.157\Software\Software\SSL Certs\mail.kemron.com (1)\2024\mail_kemron_com.crt', $binrequest.FileData)