resource "azurerm_resource_group" "main" {
  name     = "rg-drift-detection-demo"
  location = "UK South"
}

# Storage Account with Blob
resource "azurerm_storage_account" "main" {
  name                     = "stdriftdemostorage" 
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "demo"
    managed_by  = "terraform"
  }
}

resource "azurerm_storage_container" "main" {
  name                  = "drift-demo-container"
   storage_account_id   = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-drift-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "subnet-default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "nic-drift-demo-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "vm-drift-demo"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B1s" 
  admin_username      = "azureuser"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]
  admin_password = "P@ssw0rd1234!"
  # admin_ssh_key {
  #   username   = "azureuser"
  #   public_key = file("./myproject_key.pem") 
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    environment = "demo"
    managed_by  = "terraform"
  }
}

