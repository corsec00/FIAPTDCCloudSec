#####################################################
### Criado por Leonardo Santos Silva
### Data: 15 de Setembro de 2023
### Última Revisão: 8 de Setembro de 2024
### Exercício: 05 - Gerenciamento de ferramenta de criptografia (Key Vault com  Bastion & VPN) - FIAP 2TDCPR-2024
#####################################################

Clear-Host

# Definição das Variáveis
$RootCA = Read-Host "Digite o Nome do certificado ROOT da sua CA"  
$CertName = Read-Host "Digite o Nome do certificado do Cliente ou o seu nome"  
$Senha = Read-Host "Digite uma senha para exportar o certificado ROOT da sua CA para a Base64" -AsSecureString
$Senhabase64 = ConvertTo-SecureString -String $Senha -Force -AsPlainText

# Criando Certificado ROOT da CA
$params = @{
    Type = 'Custom'
    Subject = $RootCA
    KeySpec = 'Signature'
    KeyExportPolicy = 'Exportable'
    KeyUsage = 'CertSign'
    KeyUsageProperty = 'Sign'
    KeyLength = 2048
    HashAlgorithm = 'sha256'
    NotAfter = (Get-Date).AddMonths(24)
    CertStoreLocation = 'Cert:\CurrentUser\My'
}
$certROOT = New-SelfSignedCertificate @params
$certROOT

# Exportando as configurações do ROOT CA
$myThumbprint = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object { $_.Subject -like "*$RootCA*" } | Select-Object -ExpandProperty Thumbprint
$certThumb = Get-ChildItem -Path "Cert:\CurrentUser\My\$myThumbprint"

#Criando o Certificado do Cliente
$params = @{
    Type = 'Custom'
    Subject = $CertName
    DnsName = $CertName
    KeySpec = 'Signature'
    KeyExportPolicy = 'Exportable'
    KeyLength = 2048
    HashAlgorithm = 'sha256'
    NotAfter = (Get-Date).AddMonths(18)
    CertStoreLocation = 'Cert:\CurrentUser\My'
    Signer = $certROOT
    TextExtension = @(
     '2.5.29.37={text}1.3.6.1.5.5.7.3.2')
}
New-SelfSignedCertificate @params
Start-Sleep -Seconds 3

# Exporta o Root para um PFX

$Path = $RootCA+".pfx"
Export-PfxCertificate -Cert "Cert:\CurrentUser\My\$myThumbprint" -FilePath $Path -Password $Senhabase64
