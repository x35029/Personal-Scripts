Set-StrictMode -Version 2

Import-Module ActiveDirectory

# Set the working directory to the script's directory
Push-Location (Split-Path ($MyInvocation.MyCommand.Path))

#
# Global variables
#
# User properties
$ou = "OU=StandardAccounts,DC=vlab,DC=varandas,DC=com" # Which OU to create the user in
$initialPassword = 'Pa$$w0rd'             # Initial password set for the user
$orgShortName = "v"                         # This is used to build a user's sAMAccountName
$dnsDomain = "vlab.varandas.com"                      # Domain is used for e-mail address and UPN
$company = "vLab - Varandas"                      # Used for the user object's company attribute
$departments = (                             # Departments and associated job titles to assign to the users
                  @{"Name" = "Finance & Accounting"; Positions = ("VIP","Controller","Manager","SectionManager","Accountant","Analyst","Trainee")},
                  @{"Name" = "Human Resources"; Positions = ("HR-Manager", "Embedded", "Analyst", "Trainee")},
                  @{"Name" = "Sales"; Positions = ("VIP","Manager", "Representative", "Consultant")},
                  @{"Name" = "Marketing"; Positions = ("Manager", "Coordinator", "Assistant", "Specialist")},
                  @{"Name" = "Engineering"; Positions = ("Manager", "Engineer", "Scientist")},
                  @{"Name" = "Consulting"; Positions = ("Manager", "Consultant")},
                  @{"Name" = "IT"; Positions = ("VIP","Manager", "Engineer", "Technician","Analyst","Supervisor")},
                  @{"Name" = "Planning"; Positions = ("VIP","Manager", "Engineer")},
                  @{"Name" = "Contracts"; Positions = ("Manager", "Coordinator", "Clerk")},
                  @{"Name" = "Purchasing"; Positions = ("Manager", "Coordinator", "Clerk", "Purchaser")}
               )
$phoneCountryCodes = @{"DE" = "+49"}         # Country codes for the countries used in the address file

# Other parameters
$userCount = 5000                            # How many users to create
$locationCount = 20                          # How many different offices locations to use

# Files used
$firstNameFileMale = "Firstnames-m.txt"      # Format: FirstName
$firstNameFileFemale = "Firstnames-f.txt"    # Format: FirstName
$lastNameFile = "Lastnames.txt"              # Format: LastName
$addressFile = "Addresses.txt"               # Format: City,Street,State,PostalCode,Country
$postalAreaFile = "PostalAreaCode.txt"       # Format: PostalCode,PhoneAreaCode

#
# Read input files
#
$firstNamesMale = Import-CSV $firstNameFileMale
$firstNamesFemale = Import-CSV $firstNameFileFemale
$lastNames = Import-CSV $lastNameFile
$addresses = Import-CSV $addressFile
$postalAreaCodesTemp = Import-CSV $postalAreaFile

# Convert the postal & phone area code object list into a hash
$postalAreaCodes = @{}
foreach ($row in $postalAreaCodesTemp)
{
   $postalAreaCodes[$row.PostalCode] = $row.PhoneAreaCode
}
$postalAreaCodesTemp = $null

#
# Preparation
#
$securePassword = ConvertTo-SecureString -AsPlainText $initialPassword -Force

# Select the configured number of locations from the address list
$locations = @()
$addressIndexesUsed = @()
for ($i = 0; $i -le $locationCount; $i++)
{
   # Determine a random address
   $addressIndex = -1
   do
   {
      $addressIndex = Get-Random -Minimum 0 -Maximum $addresses.Count
   } while ($addressIndexesUsed -contains $addressIndex)
   
   # Store the address in a location variable
   $street = $addresses[$addressIndex].Street
   $city = $addresses[$addressIndex].City
   $state = $addresses[$addressIndex].State
   $postalCode = $addresses[$addressIndex].PostalCode
   $country = $addresses[$addressIndex].Country
   $locations += @{"Street" = $street; "City" = $city; "State" = $state; "PostalCode" = $postalCode; "Country" = $country}
   
   # Do not use this address again
   $addressIndexesUsed += $addressIndex
}

#
# Create the users
#
for ($i = 0; $i -lt $userCount; $i++)
{
   #
   # Randomly determine this user's properties
   #
   
   # Sex & name
   [bool] $male = Get-Random -Minimum 0 -Maximum 2
   $firstName = ""
   if ($male)
   {
      $firstName = $firstNamesMale[$(Get-Random -Minimum 0 -Maximum $firstNamesMale.Count)].FirstName
   }
   else
   {
      $firstName = $firstNamesFemale[$(Get-Random -Minimum 0 -Maximum $firstNamesFemale.Count)].FirstName
   }
   $lastName = $lastNames[$(Get-Random -Minimum 0 -Maximum $lastNames.Count)].LastName
   $displayName = "$firstName $lastName"

   # Address
   $locationIndex = Get-Random -Minimum 0 -Maximum $locations.Count
   $street = $locations[$locationIndex].Street
   $city = $locations[$locationIndex].City
   $state = $locations[$locationIndex].State
   $postalCode = $locations[$locationIndex].PostalCode
   $country = $locations[$locationIndex].Country
   
   # Department & title
   $departmentIndex = Get-Random -Minimum 0 -Maximum $departments.Count
   $department = $departments[$departmentIndex].Name
   $title = $departments[$departmentIndex].Positions[$(Get-Random -Minimum 0 -Maximum $departments[$departmentIndex].Positions.Count)]

   # Phone number
   if (-not $phoneCountryCodes.ContainsKey($country))
   {
      "ERROR: No country code found for $country"
      continue
   }
   if (-not $postalAreaCodes.ContainsKey($postalCode))
   {
      "ERROR: No country code found for $country"
      continue
   }
   $officePhone = $phoneCountryCodes[$country] + "-" + $postalAreaCodes[$postalCode].Substring(1) + "-" + (Get-Random -Minimum 100000 -Maximum 1000000)
   
   # Build the sAMAccountName: $orgShortName + employee number
   $employeeNumber = Get-Random -Minimum 100000 -Maximum 1000000
   $sAMAccountName = $orgShortName + $employeeNumber
   $userExists = $false
   Try   { $userExists = Get-ADUser -LDAPFilter "(sAMAccountName=$sAMAccountName)" }
   Catch { }
   if ($userExists)
   {
      $i--
      continue
   }

   #
   # Create the user account
   #
   New-ADUser -SamAccountName $sAMAccountName -Name $displayName -Path $ou -AccountPassword $securePassword -Enabled $true -GivenName $firstName -Surname $lastName -DisplayName $displayName -EmailAddress "$firstName.$lastName@$dnsDomain" -StreetAddress $street -City $city -PostalCode $postalCode -State $state -Country $country -UserPrincipalName "$sAMAccountName@$dnsDomain" -Company $company -Department $department -EmployeeNumber $employeeNumber -Title $title -OfficePhone $officePhone

   "Created user #" + ($i+1) + ", $displayName, $sAMAccountName, $title, $department, $street, $city"
}