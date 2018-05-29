#############################################
# Check_nimble Script 
# Darren Enders
# May 2018 
#############################################


###########################
# Setup the parameters
###########################

[CmdletBinding(DefaultParametersetName='None')]

param(
    [Parameter(Mandatory=$true)] [string]$arrayAddress = "192.168.90.101",
    [Parameter(Mandatory=$true)] [string]$userName = "readonlyid",
    [Parameter(Mandatory=$true)] [string]$password = "HelpDesk2018",
    [Parameter(ParameterSetName='PowerSupplyCheck',Mandatory=$false)][switch]$powersupply,
    [Parameter(ParameterSetName='PowerSupplyCheck',Mandatory=$true)][string]$side
    
    )



if ($checkname -eq "") {
	write-host "`n`nUsage: check_nimble -checkname [name of check] `n`nPowerSupply -> status of power supplies";
	exit
}


###########################
# Enable HTTPS
###########################

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

###########################
# Get Token
###########################
$data = @{
    username = $userName
	password = $password
}

$body = convertto-json (@{ data = $data })

$uri = "https://" + $arrayAddress + ":5392/v1/tokens"
$token = Invoke-RestMethod -Uri $uri -Method Post -Body $body
$token = $token.data.session_token

if ($powersupply -eq $true) {
  ###########################
  # Check PowerSupplies
  ###########################
  $header = @{ "X-Auth-Token" = $token }
  $uri = "https://" + $array + ":5392/v1/shelves/detail"
  $shelf_list = Invoke-RestMethod -Uri $uri -Method Get -Header $header

  $intPS = $shelf_list.data.chassis_sensors

  foreach ($ps in $intPS )
  {
     
     if($side.ToLower() -eq 'left' -or $side.ToLower() -eq 'right')
     {
       if($ps.location -eq $side.ToLower()+" rear")
       {
         write-host $side.ToUpper() " PowerSupply " $ps.status
         Write-Host
       }

     }
     else
     {
       write-host "Side must be left or right"
       break;
     }
     
  }


}




###########################
# Get Volume List
###########################

$header = @{ "X-Auth-Token" = $token }
$uri = "https://" + $array + ":5392/v1/volumes/detail"
$volume_list = Invoke-RestMethod -Uri $uri -Method Get -Header $header
$vol_array = @();
foreach ($volume_id in $volume_list.data.id){
	
	$uri = "https://" + $array + ":5392/v1/volumes/" + $volume_id
	$volume = Invoke-RestMethod -Uri $uri -Method Get -Header $header
	#write-host $volume.data.name :     $volume.data.id
	$vol_array += $volume.data
	
}

###########################
# Print Results
###########################

#$vol_array | sort-object size,name -descending | select size,name,online | format-table -autosize
#$volume_list.data | Select name,size,online,total_usage_bytes | format-table -autosize

###########################
# Check PowerSupplies
###########################

#if
$header = @{ "X-Auth-Token" = $token }
$uri = "https://" + $array + ":5392/v1/shelves/detail"
$shelf_list = Invoke-RestMethod -Uri $uri -Method Get -Header $header
$shelf_array = @();

$powersupplies = $shelf_list.data.chassis_sensors
$shelf1 = $shelf_list.data.ctrlrs[0]
$shelf2 = $shelf_list.data.ctrlrs[1]

