#####################################################
### Criado por Leonardo Santos Silva
### Data: 2 de Outubro de 2023
### Última Revisão: 4 de Setembro de 2024
### Exercício: 02-Gerenciamento de IP - FIAP 2TDCPR-2024
### Execute o seguinte comando no Azure CLI:
### pwsh -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/corsec00/FIAPTDCCloudSec/main/estruturaRedeAzure.ps1' -OutFile 'estruturaRedeAzure.ps1'; ./estruturaRedeAzure.ps1"
#####################################################

# Loga no seu ambiente Azure
# az login
Clear-Host
#Lista os valores de Regiões (BASTION Free está em West US, East US 2 e North Central US)
# az account list-locations --query "[*].name" | ConvertFrom-Json | sort | where { $_ -like "*us*" }

#Atualizando módulo do Bastion
# az extension add --upgrade -n bastion --allow-preview false

# Cria estrutura de acesso baseado na localidade	
$Loc = Read-Host "Digite a região onde os recursos serão criados (escolha entre northcentralus, westus e eastus2)"  
$RegionGroup = Read-Host "Digite a região onde os recursos serão criados (ncu, wus, eu2)"
$Sufix = Read-Host "Digite sufixo dos recursos que serão criados (ex: leosantos001)"
# $Sufix = 'leoss001'
$RG = 'RG-SuporteLSS001'
$DNS = 'MyDNS' +$Sufix
# $Loc = 'northcentralus'
$VNet4 = 'vnet-' +$Sufix
$BST ='bst-'+$RegionGroup +'-' +$Sufix
$PIPBastion = "pip-" +$RegionGroup +'-'+$Sufix
# Definindo o endereçamento de rede
if ($RegionGroup -eq "wus") {
    $ip = "10.1."
} elseif ($RegionGroup -eq "ncu") {
    $ip = "10.2."
} elseif ($RegionGroup -eq "eu2") {
    $ip = "10.3."
} else {
    Write-Host "Valor inválido. Por favor, insira ncu, eu2 ou neu."
    exit
}
$AddrSpace = $ip +"0.0/16"
$IPBst= $ip +"0.0/27"
$IPWindows = $ip +"1.0/24"
$IPLinux = $ip +"2.0/24"
$IPK8 = $ip +"3.0/24"


Write-Host "Para a Região" $Loc "será criado a VNET" $VNet4 "usando o Bastion" $BST "(IP Público:" $PIPBastion") com o Address Space" $AddrSpace "e com as seguintes subnets:"
Write-Host "Rede Bastion:" $IPBst 
Write-Host "Windows:" $IPWindows
Write-Host "Linux:" $IPLinux
Write-Host "Kubernetes:" $IPK8 

# create ASG
az network asg create -g $RG -n asg-$RegionGroup-Kubernetes --location $Loc
az network asg create -g $RG -n asg-$RegionGroup-Windows --location $Loc
az network asg create -g $RG -n asg-$RegionGroup-Linux --location $Loc

#Create NSG 
az network nsg create -g $RG -n nsg-$RegionGroup-Linux --location $Loc
az network nsg create -g $RG -n nsg-$RegionGroup-Kubernetes --location $Loc
az network nsg create -g $RG -n nsg-$RegionGroup-Windows --location $Loc

# Create VNet
az network vnet create --resource-group $RG --name $VNet4 --location $Loc --address-prefix $AddrSpace

# Create NSG Kubernetes
az network nsg rule create -g $RG --nsg-name nsg-$RegionGroup-Kubernetes -n Kubernetes-API-Server --destination-asgs asg-$RegionGroup-Kubernetes --priority 230 --destination-port-ranges 6443  --access Allow --protocol Tcp --source-address-prefixes '*'
az network nsg rule create -g $RG --nsg-name nsg-$RegionGroup-Kubernetes -n Kubelet-API --destination-asgs asg-$RegionGroup-Kubernetes --priority 232 --destination-port-ranges 10250  --access Allow --protocol Tcp --source-address-prefixes '*'
az network nsg rule create -g $RG --nsg-name nsg-$RegionGroup-Kubernetes -n Kube-Scheduler --destination-asgs asg-$RegionGroup-Kubernetes --priority 233 --destination-port-ranges 10259  --access Allow --protocol Tcp --source-address-prefixes '*'
az network nsg rule create -g $RG --nsg-name nsg-$RegionGroup-Kubernetes -n Kube-Controler-Manager --destination-asgs asg-$RegionGroup-Kubernetes --priority 234 --destination-port-ranges 10257  --access Allow --protocol Tcp --source-address-prefixes '*'
az network nsg rule create -g $RG --nsg-name nsg-$RegionGroup-Kubernetes -n SSHInbound --destination-asgs asg-$RegionGroup-Kubernetes --priority 236 --destination-port-ranges 22  --access Allow --protocol Tcp --source-address-prefixes '*'
az network nsg rule create -g $RG --nsg-name nsg-$RegionGroup-Kubernetes -n etcd-Server-Client-API --destination-asgs asg-$RegionGroup-Kubernetes --priority 231 --destination-port-ranges 2379-2380  --access Allow --protocol Tcp --source-address-prefixes '*'
az network nsg rule create -g $RG --nsg-name nsg-$RegionGroup-Kubernetes -n NodePort-Services --destination-asgs asg-$RegionGroup-Kubernetes --priority 235 --destination-port-ranges 30000-32767  --access Allow --protocol Tcp --source-address-prefixes '*'
# Create NSG Linux
az network nsg rule create -g $RG --nsg-name nsg-$RegionGroup-Linux -n SSHInbound --destination-asgs asg-$RegionGroup-Linux --priority 200 --destination-port-ranges 22  --access Allow --protocol Tcp --source-address-prefixes '*'
# Create NSG Windows
az network nsg rule create -g $RG --nsg-name nsg-$RegionGroup-Windows -n RDPInbound --destination-asgs asg-$RegionGroup-Windows --priority 200 --destination-port-ranges 3389  --access Allow --protocol Tcp --source-address-prefixes '*'
az network nsg rule create -g $RG --nsg-name nsg-$RegionGroup-Windows -n SMBInbound --destination-asgs asg-$RegionGroup-Windows --priority 220 --destination-port-ranges 445 139 138 137  --access Allow --protocol '*' --source-address-prefixes '*'

# Create subnets
az network vnet subnet create --resource-group $RG --vnet-name $VNet4 --name AzureBastionSubnet --address-prefix $IPBst
az network vnet subnet create --resource-group $RG --vnet-name $VNet4 --name VM-Windows --address-prefix $IPWindows --network-security-group nsg-$RegionGroup-Windows --private-endpoint-network-policies Enabled
az network vnet subnet create --resource-group $RG --vnet-name $VNet4 --name VM-Linux --address-prefix $IPLinux --network-security-group nsg-$RegionGroup-Linux --private-endpoint-network-policies Enabled
az network vnet subnet create --resource-group $RG --vnet-name $VNet4 --name VM-Kubernetes --address-prefix $IPK8  --network-security-group nsg-$RegionGroup-Kubernetes --private-endpoint-network-policies Enabled

# Criando um link entre a VNet e o Private DNS Zone
az network private-dns link vnet create --resource-group $RG --zone-name leoseg.cloud --name $DNS --virtual-network $VNet4 --registration-enabled true


# Criando um Bastion
if ($RegionGroup -eq "ncu" -or $RegionGroup -eq "wus") {
    az network public-ip create --resource-group $RG --name $PIPBastion --sku Standard --location $Loc
    # az network bastion create --name $BST --resource-group $RG --vnet-name $VNet4 --public-ip-address $PIPBastion --sku Developer --location $Loc
    Write-Host "Crie o seu Bastion manualmente, pois via CLI não é aceita a SKU de Developer (gratuito). Use o IP Público" +$PIPBastion
    
} elseif ($RegionGroup -eq "eu2") {
    Write-Host "Não existe Bastion com SKU de Developer nesta Região. O Bastion não será criado."
} else {
    Write-Host "Valor não corresponde a nenhuma condição específica."
}

$input = Read-Host "Todas as VNets já foram criadas? (S/N)"

# Verifica a entrada do usuário
if ($input -eq "S") {
    Write-Host "Criando os Peerings entre as VNets..."

    # Defina as VNets
    $VNet1 = 'vnet-leoss001'
    $VNet2 = 'vnet-leoss002'
    $VNet3 = 'vnet-leoss003'
        
    # Obtendo o ID das VNets
        $vnet1Id=(az network vnet show --resource-group $RG --name $VNet1 --query id --output tsv)
        $vnet2Id=(az network vnet show --resource-group $RG --name $VNet2 --query id --output tsv)
        $vnet3Id=(az network vnet show --resource-group $RG --name $VNet4 --query id --output tsv)

        # Criando Peering de 01 para 03
        az network vnet peering create --name VNet01ToVNet03 --resource-group $RG --vnet-name $VNet1 --remote-vnet $vnet3Id --allow-vnet-access
        az network vnet peering create --name VNet03ToVNet01 --resource-group $RG --vnet-name $VNet3 --remote-vnet $vnet1Id --allow-vnet-access

        # Criando Peering de 02 para 03
        az network vnet peering create --name VNet02ToVNet03 --resource-group $RG --vnet-name $VNet2 --remote-vnet $vnet3Id --allow-vnet-access
        az network vnet peering create --name VNet03ToVNet02 --resource-group $RG --vnet-name $VNet3 --remote-vnet $vnet2Id --allow-vnet-access

        # Criando Peering de 01 para 02
        az network vnet peering create --name VNet01ToVNet02 --resource-group $RG --vnet-name $VNet1 --remote-vnet $vnet2Id --allow-vnet-access
        az network vnet peering create --name VNet02ToVNet01 --resource-group $RG --vnet-name $VNet2 --remote-vnet $vnet1Id --allow-vnet-access


} elseif ($input -eq "N") {
    Write-Host "Encerrando o script."
    exit
} else {
    Write-Host "Entrada inválida. Por favor, digite 'S' ou 'N'."
}