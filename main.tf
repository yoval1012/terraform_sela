resource "azurerm_resource_group" "rg-library-dev" {
  name     = var.rg  
  location = var.azure_region
  tags = {
    environment = "dev"
    project     = "myproject"
 }
}


resource "azurerm_virtual_network" "vnet1" { 
  name                = "vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = var.azure_region
  resource_group_name = var.rg
  subnet {
    name           = "snet-web"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "snet-db"
    address_prefix = "10.0.2.0/24"
  }
}

 resource "azurerm_network_security_group" "nsg1" {
  name                = "nsg1"
  location            = azurerm_virtual_network.vnet1.location
  resource_group_name = azurerm_virtual_network.vnet1.resource_group_name
}

resource "azurerm_network_security_rule" "inbound_rule_nsg1_world" {
  name                        = "AllowWebTraffic"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_virtual_network.vnet1.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg1.name
}
# Define an inbound security rule for NSG1 (open SSH on port 22)
resource "azurerm_network_security_rule" "inbound_ssh_rule_nsg1" {
  name                        = "AllowSSHToNSG1"
  priority                    = 1002  # Adjust the priority as needed to avoid conflicts with existing rules
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_virtual_network.vnet1.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg1.name
}


resource "azurerm_network_security_group" "nsg2" {
  name                = "nsg2"
  location            = azurerm_virtual_network.vnet1.location
  resource_group_name = azurerm_virtual_network.vnet1.resource_group_name
}

# Define an inbound security rule for NSG2 (open only to subnet1 on port 5432)
resource "azurerm_network_security_rule" "inbound_rule_nsg2_subnet1" {
  name                        = "AllowPostgresFromSubnet1"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"  # Allow traffic from any source port
  destination_port_range      = "5432"  # Specify the port you want to allow traffic on
  source_address_prefix       = "10.0.1.0/24"  # Specify the source IP address range
  destination_address_prefix  = "*"  # Allow traffic to any destination
  resource_group_name         = azurerm_virtual_network.vnet1.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg2.name
}


# Define an inbound security rule for NSG2 (open SSH on port 22)
resource "azurerm_network_security_rule" "inbound_ssh_rule_nsg2" {
  name                        = "AllowSSHToNSG2"
  priority                    = 1002  # Adjust the priority as needed to avoid conflicts with existing rules
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_virtual_network.vnet1.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg2.name
}

data "azurerm_subnet" "subnet1" {
  name                 = var.subnet1
  virtual_network_name = azurerm_virtual_network.vnet1.name
  resource_group_name  = azurerm_virtual_network.vnet1.resource_group_name
}

data "azurerm_subnet" "subnet2" {
  name                 = var.subnet2
  virtual_network_name = azurerm_virtual_network.vnet1.name
  resource_group_name  = azurerm_virtual_network.vnet1.resource_group_name
}


# Associate the first NSG with the first VNet's subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association1" {
  network_security_group_id = azurerm_network_security_group.nsg1.id
  subnet_id                = data.azurerm_subnet.subnet1.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association2" {
  network_security_group_id = azurerm_network_security_group.nsg2.id
  subnet_id                = data.azurerm_subnet.subnet2.id
}


resource "tls_private_key" "web_ssh_vm1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "web_ssh_vm2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "vm1_private_key" {
  filename = "${path.module}/vm1_key.pem"
  content  = tls_private_key.web_ssh_vm1.private_key_pem
}

resource "local_file" "vm2_private_key" {
  filename = "${path.module}/vm2_key.pem"
  content  = tls_private_key.web_ssh_vm2.private_key_pem
}

# ---------------------------------------------------------------------vm1

resource "azurerm_network_interface" "nic1" {
  name                = "example-nic1"
  location            = var.azure_region
  resource_group_name = var.rg

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet1.id 
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
  }
  # Public IP configuration
   enable_ip_forwarding = true  # This enables IP forwarding
   tags = {
     environment = "dev"
  }
}

resource "azurerm_virtual_machine" "vm1" {
  name                  = "example-vm1"
  location              = var.azure_region
  resource_group_name   = var.rg
  network_interface_ids = [azurerm_network_interface.nic1.id]
  vm_size               = "Standard_DS2_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  storage_os_disk {
  name              = "osdisk_vm1"
  caching           = "ReadWrite"
  create_option     = "FromImage"
  managed_disk_type = "StandardSSD_LRS"
  }
  
  os_profile {
    computer_name  = "hostname1"
    admin_username = "yuvalleibovich"
  
  }
  
  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/yuvalleibovich/.ssh/authorized_keys"
      key_data = tls_private_key.web_ssh_vm1.public_key_openssh
    }
  }


 
#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt-get update",
#       "sudo apt-get install -y python3-pip",
#       "sudo pip3 install Flask",
#       "echo $(hostname -I) >> output.txt"
#     ]
#   }
#   connection {
#   type     = "ssh"
#   user     = "yuvalleibovich"  
#   host     = "10.0.1.4"
#   private_key = file("~/.ssh/id_rsa_vm1")
# }

 }
 
resource "azurerm_virtual_machine_extension" "install_flask" {
  name                 = "install-flask"
  virtual_machine_id   = azurerm_virtual_machine.vm1.id  
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {
        "script": "${base64encode(file("${path.module}/install-flask.sh"))}"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {}
PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_machine.vm1  
  ]
}

#--------------------------------------------------------------------vm2




resource "azurerm_network_interface" "nic2" {
  name                = "example-nic2"
  location            = var.azure_region
  resource_group_name = var.rg

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.5"
  }
}

resource "azurerm_virtual_machine" "vm2" {
  name                  = "vm2"
  location              = var.azure_region
  resource_group_name   = var.rg
  network_interface_ids = [azurerm_network_interface.nic2.id]
  vm_size               = "Standard_DS2_v2"
  
  
  storage_image_reference {
    publisher = "Canonical" #apps-4-rent    cloud-infrastructure-services
    offer     = "UbuntuServer" #flask-django-on-ubuntu22    postgresql-ubuntu
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-vm2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }
  
  os_profile {
    computer_name  = "hostname2"
    admin_username = "yuvalleibovich"

    
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/yuvalleibovich/.ssh/authorized_keys"
      key_data = tls_private_key.web_ssh_vm2.public_key_openssh
    }
  }



  
  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo apt-get update",
  #     "sudo apt-get install -y postgresql",
  #     "echo $(hostname -I) >> output.txt"
  #   ]
  # }
  # connection {
  # type        = "ssh"
  # user        = "yuvalleibovich"
  # host        = "10.0.2.5"
  # private_key = file("~/.ssh/id_rsa_vm2") 
  # }
}

resource "azurerm_virtual_machine_extension" "install_postgresql" {
  name                 = "install-postgresql"
  virtual_machine_id   = azurerm_virtual_machine.vm2.id  
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {
        "script": "${base64encode(file("${path.module}/install_postgresql.sh"))}"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {}
PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_machine.vm2  
  ]
}

 


