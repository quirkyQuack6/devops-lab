terraform {
  required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.9.8" 
    }
  }
}

# Подключаемся к локальному KVM
provider "libvirt" {
  uri = "qemu:///system"
}

# 1. Скачиваем базовый образ Ubuntu Server из официального облачного репозитория
resource "libvirt_volume" "ubuntu_base" {
  name = "ubuntu-base-volume"
  pool = "default"
  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    }
  }
}

resource "libvirt_pool" "home_pool" {
  name     = "kvm_home_pool"
  type     = "dir"

  target = {
    path = "/home/vova/kvm-images"
  }
}

# 2. Создаем индивидуальный виртуальный диск для будущей ВМ на основе скачанного образа
resource "libvirt_volume" "vm1_disk" {
  name 		 = "homelab-target-disk.qcow2"
  pool 		 = libvirt_pool.home_pool.name
  target = {
    format = {
      type  = "qcow2"
    }
  }

  capacity = 15032385536 

  backing_store = {
    path = libvirt_volume.ubuntu_base.path
    format = {
      type = "qcow2"
    }
  }
}

# 3. Настройка Cloud-Init
# Этот блок создаст ISO-образ настроек, который KVM подключит к виртуалке
resource "libvirt_cloudinit_disk" "vm1_init" {
  name = "vm1_cloudinit"
  user_data = templatefile(
    "${path.module}/cloud-init.yaml.tftpl",
    {
      ssh_public_key = trimspace(file("/home/vova/.ssh/id_ed25519.pub"))
    }
  )
  meta_data = file("${path.module}/meta-data")
  network_config = file("${path.module}/network-config")
}

# 3.1. Загружаем ISO-образ Cloud-Init в пул libvirt (обязательно для v0.9.x)
resource "libvirt_volume" "vm1_cloudinit" {
  name = "vm1_cloudinit.iso"
  pool = libvirt_pool.home_pool.name

  create = {
    content = {
      url = libvirt_cloudinit_disk.vm1_init.path
    }
  }
}

# 4. Описываем саму виртуальную машину
resource "libvirt_domain" "homelab_vm" {
  name 	 = "homelab-devops-node"
  type	 = "kvm"
  memory = 2097152
  vcpu	 = 2

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type = "hvm"
    type_arch = "x86_64"
    type_machine = "pc"
  }

  devices = {
    # Привязываем диски
    disks = [
        {
        # Основной диск
        source = {
          volume = {
            pool	 = libvirt_volume.vm1_disk.pool
            volume = libvirt_volume.vm1_disk.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }

        driver = {
          type = "qcow2"
          name = "qemu"
        }
      },
      {
        # Подключаем Cloud-Init как CD-ROM (вместо удаленного атрибута cloudinit)
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.vm1_cloudinit.pool
            volume = libvirt_volume.vm1_cloudinit.name	
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
        driver = {
          type = "raw"
          name = "qemu"
        }
      }
    ]

    interfaces = [
      {
        type = "network"
        source = {
          network = {
            network = "default"
          }
        }
        model = { type = "virtio" }
        wait_for_ip = {
          timeout = 150
          source  = "lease"
        }
      }
    ]

    serial = [
      {
        type = "pty"
        target = {}
      }
    ]

    console = [
      {
        type   = "pty"
        target = {}
      }
    ]
	
    #graphics = [
    #  {
    #    type = "spice"
    #    spice = {
    #      auto_port = true
    #      listeners = [
    #        {
    #          address = {}
    #        }
    #      ]
    #    }
    #  }
    #]

    #videos = [
    # {
    #   model = {
    #     type 		= "virtio"
    #     heads		= 1
    #     primary = "yes"
    #   }
    # }
    #]
  }
  running = true
}

# 5. Просим Terraform вывести IP-адрес созданной машины, когда он закончит
data "libvirt_domain_interface_addresses" "vm_ip" {
  domain = libvirt_domain.homelab_vm.name
  source = "lease"
}

output "interfaces" {
  value = data.libvirt_domain_interface_addresses.vm_ip.interfaces[0].addrs[0].addr
}
