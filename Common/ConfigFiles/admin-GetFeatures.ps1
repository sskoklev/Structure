# The commands below retun 3 columns.
# The column used to populate the WindowsFeatures.xml file is 'Name'

# Get a list of all available features
Get-WindowsFeature

# Get a list of features that are already installed
Get-WindowsFeature | Where Installed

# Get a list of features that start with the letters AD
Get-WindowsFeature -Name AD*

