git clone https://github.com/corsec00/FIAPTDCCloudSec.git
cd FIAPTDCCloudSec
$RG = Read-Host "Digite o Nome do Resource Group"
az deployment group create --resource-group $RG --template-file template.json --parameters @parameters.json