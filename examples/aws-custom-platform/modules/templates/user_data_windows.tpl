<powershell>
$admin = [adsi]("WinNT://./administrator, user")
$admin.psbase.invoke("SetPassword", "${win_admin_password}")

# Snippet to enable WinRM over HTTPS with a self-signed certificate
# from https://gist.github.com/TechIsCool/d65017b8427cfa49d579a6d7b6e03c93
Write-Output "Disabling WinRM over HTTP..."
Disable-NetFirewallRule -Name "WINRM-HTTP-In-TCP"
Disable-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC"
Get-ChildItem WSMan:\Localhost\listener | Remove-Item -Recurse

Write-Output "Configuring WinRM for HTTPS..."
Set-Item -Path WSMan:\LocalHost\MaxTimeoutms -Value '1800000'
Set-Item -Path WSMan:\LocalHost\Shell\MaxMemoryPerShellMB -Value '1024'
Set-Item -Path WSMan:\LocalHost\Service\AllowUnencrypted -Value 'false'
Set-Item -Path WSMan:\LocalHost\Service\Auth\Basic -Value 'true'
Set-Item -Path WSMan:\LocalHost\Service\Auth\CredSSP -Value 'true'

New-NetFirewallRule -Name "WINRM-HTTPS-In-TCP" `
    -DisplayName "Windows Remote Management (HTTPS-In)" `
    -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" `
    -Group "Windows Remote Management" `
    -Program "System" `
    -Protocol TCP `
    -LocalPort "5986" `
    -Action Allow `
    -Profile Domain,Private

New-NetFirewallRule -Name "WINRM-HTTPS-In-TCP-PUBLIC" `
    -DisplayName "Windows Remote Management (HTTPS-In)" `
    -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" `
    -Group "Windows Remote Management" `
    -Program "System" `
    -Protocol TCP `
    -LocalPort "5986" `
    -Action Allow `
    -Profile Public

[string[]] $Hostname = @([System.Net.Dns]::GetHostByName((hostname)).HostName.ToUpper())
$metadata = @('public-hostname','public-ipv4')
foreach ($item in $metadata) {
    if ($response = Invoke-WebRequest -Uri "http://169.254.169.254/latest/meta-data/$item" -UseBasicParsing -ErrorAction Continue) {
        if ($response.StatusCode -eq 200) {
          $Hostname += $response.Content
        }
        else {
            Write-Warning "Received unexpected response code [$($response.StatusCode)] from EC2 instance metadata [$item] request."
        }
      }
      else {
          Write-Warning "Unable to access EC2 instance [$item] metadata!"
      }
}
$pfx = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $Hostname
$certThumbprint = $pfx.Thumbprint
$certSubjectName = $pfx.SubjectName.Name.TrimStart("CN = ").Trim()

New-Item -Path WSMan:\LocalHost\Listener -Address * -Transport HTTPS -Hostname $certSubjectName -CertificateThumbPrint $certThumbprint -Port "5986" -force

Write-Output "Restarting WinRM Service..."
Stop-Service WinRM
Set-Service WinRM -StartupType "Automatic"
Start-Service WinRM

# Setup SSH
$metadataUrl = "http://169.254.169.254/1.0/meta-data/public-keys/0/openssh-key"
$sshCapability = 'OpenSSH.Server~~~~0.0.1.0'
$sshServiceName = 'sshd'
$sshConfigPath = Join-Path -Path $env:ProgramData -ChildPath "\ssh\sshd_config"
Try {
    $response = Invoke-Webrequest -Uri $metadataUrl -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        # We were able to obtain the public key so proceed with setting up SSH service
        if ((Get-WindowsCapability -Online -Name $sshCapability).State -ne 'Installed') {
            $null = Add-WindowsCapability -Online -Name $sshCapability
        }
        if (Get-Service -Name $sshServiceName -ErrorAction SilentlyContinue) {
            New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
            Set-Service -Name $sshServiceName -StartupType Automatic
            Start-Service -Name $sshServiceName
            Start-Sleep -Seconds 3
            Try {
                $openSshKeyPath = Join-Path -Path $env:USERPROFILE -ChildPath '.ssh'
                if (-not(Test-Path -Path $openSshKeyPath -PathType Container)) {
                    $null = New-Item -Path $openSshKeyPath -ItemType Directory -ErrorAction Stop
                }
                $authorizedKeyPath = Join-Path -Path $openSshKeyPath -ChildPath 'authorized_keys'
                $response.Content | Out-File -FilePath $authorizedKeyPath -Encoding ascii -NoNewline -Force -ErrorAction Stop
                # Disable password based SSH access
                if (Test-Path -Path $sshConfigPath -PathType Leaf) {
                    $sshConfigContent = Get-Content -Raw $sshConfigPath
                    $replaceString = '#PubkeyAuthentication yes'
                    $sshConfigContent = $sshConfigContent.Replace($replaceString, ($replaceString.TrimStart('#') + [System.Environment]::NewLine + 'AuthenticationMethods publickey'))
                    $replaceString = 'Match Group administrators'
                    $sshConfigContent = $sshConfigContent.Replace($replaceString, ('#' + $replaceString))
                    $replaceString = '       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys'
                    $sshConfigContent = $sshConfigContent.Replace($replaceString, ('#' + $replaceString))
                    $sshConfigContent | Out-File -FilePath $sshConfigPath -Encoding ascii
                    Restart-Service -Name $sshServiceName
                }
                else {
                    Write-Warning "SSH Service config file [$sshConfigPath] missing.  Unable to apply updated configuration settings."
                }
            }
            Catch {
                Write-Warning "Unable to save public key to file [$authorizedKeyPath] to allow SSH access."
            }
        }
        else {
            Write-Warning "Unable to install the SSH service.  System will not be accessible via SSH."
        }
    }
    else {
        Write-Warning "Received unexpected response code [$($response.StatusCode)] from EC2 instance metadata URL [$metadataUrl].  Unable to configure SSH access."
    }
}
Catch {
    Write-Warning "Exception accessing URL [$metadataUrl]. Reason: $($_.Exception.Message).  Unable to configure SSH access."
}
</powershell>
