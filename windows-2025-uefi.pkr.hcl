packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
    qemu = {
      version = "1.1.2"
      source  = "github.com/hashicorp/qemu"
    }
    # see https://github.com/hashicorp/packer-plugin-proxmox
    proxmox = {
      version = "1.2.0"
      source  = "github.com/hashicorp/proxmox"
    }
    # see https://github.com/hashicorp/packer-plugin-vagrant
    vagrant = {
      version = "1.1.5"
      source  = "github.com/hashicorp/vagrant"
    }
    # see https://github.com/hashicorp/virtualbox
    virtualbox = {
      version = "1.1.2"
      source  = "github.com/hashicorp/virtualbox"
    }    
    # see https://github.com/rgl/packer-plugin-windows-update
    windows-update = {
      version = "0.16.10"
      source  = "github.com/rgl/windows-update"
    }
  }
}

variable "disk_size" {
  type    = string
  default = "61440"
}

variable "iso_url" {
  type    = string
  default = env("WINDOWS_2025_ISO_URL")
}

variable "iso_checksum" {
  type    = string
  default = env("WINDOWS_2025_ISO_CHECKSUM")
}

variable "proxmox_node" {
  type    = string
  default = env("PROXMOX_NODE")
}

variable "vagrant_box" {
  type = string
}

variable "virtual_box_ssh_host_port" {
  type = number
  default = 2222
}

source "virtualbox-iso" "windows-2025-uefi-amd64" {
  cpus      = 2
  memory    = 4096
  disk_size = var.disk_size
  cd_files = [
    "windows-2025-uefi/virtualbox/autounattend.xml",
    "provision-autounattend.ps1",
    "provision-openssh.ps1",
    "provision-psremoting.ps1",
    "provision-pwsh.ps1",
    "provision-vmtools.ps1",
    "provision-winrm.ps1",
  ]
  guest_additions_interface = "sata"
  guest_additions_mode      = "attach"
  guest_os_type             = "Windows2025_64"
  hard_drive_interface      = "sata"
  headless                  = true
  iso_url                   = var.iso_url
  iso_checksum              = var.iso_checksum
  iso_interface             = "sata"
  shutdown_command          = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  vboxmanage = [
    ["storagectl", "{{ .Name }}", "--name", "IDE Controller", "--remove"],
    ["modifyvm", "{{.Name}}", "--firmware", "efi"],
    ["modifyvm", "{{ .Name }}", "--vrde", "off"],
    ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vboxsvga"],
    ["modifyvm", "{{ .Name }}", "--vram", "128"],
    ["modifyvm", "{{ .Name }}", "--accelerate3d", "on"],
    ["modifyvm", "{{ .Name }}", "--usb", "on"],
    ["modifyvm", "{{ .Name }}", "--mouse", "usbtablet"],
    ["modifyvm", "{{ .Name }}", "--audio", "none"],
    ["modifyvm", "{{ .Name }}", "--nictype1", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--nictype2", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--nictype3", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--nictype4", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--hpet", "on"],
    ["modifyvm", "{{ .Name }}", "--natpf1", "delete", "packercomm"],
    ["modifyvm", "{{ .Name }}", "--natpf1", "packercomm,tcp,0.0.0.0,${var.virtual_box_ssh_host_port},,22"],
    ["modifyvm", "{{ .Name }}", "--natpf1", "packercomm_wsl,tcp,127.0.0.1,${var.virtual_box_ssh_host_port},,22"],
    ["modifyvm", "{{ .Name }}", "--natpf1", "packercomm_wsl_2,tcp,,${var.virtual_box_ssh_host_port},,22"]
  ]
  boot_wait      = "3s"
  boot_command   = ["<up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait>"]
  communicator   = "ssh"
  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "4h"
  ssh_host_port_min = var.virtual_box_ssh_host_port
  ssh_host_port_max = var.virtual_box_ssh_host_port
}

source "qemu" "windows-2025-uefi-amd64" {
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = 2
  memory       = 4096
  qemuargs = [
    ["-bios", "/usr/share/ovmf/OVMF.fd"],
    ["-cpu", "host"],
    ["-device", "qemu-xhci"],
    ["-device", "virtio-tablet"],
    ["-device", "virtio-scsi-pci,id=scsi0"],
    ["-device", "scsi-hd,bus=scsi0.0,drive=drive0"],
    ["-device", "virtio-net,netdev=user.0"],
    ["-vga", "qxl"],
    ["-device", "virtio-serial-pci"],
    ["-chardev", "socket,path=/tmp/{{ .Name }}-qga.sock,server,nowait,id=qga0"],
    ["-device", "virtserialport,chardev=qga0,name=org.qemu.guest_agent.0"],
    ["-chardev", "spicevmc,id=spicechannel0,name=vdagent"],
    ["-device", "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"],
    ["-spice", "unix,addr=/tmp/{{ .Name }}-spice.socket,disable-ticketing"],
  ]
  boot_wait      = "1s"
  boot_command   = ["<up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait>"]
  disk_interface = "virtio-scsi"
  disk_cache     = "unsafe"
  disk_discard   = "unmap"
  disk_size      = var.disk_size
  cd_label       = "PROVISION"
  cd_files = [
    "drivers/NetKVM/2k25/amd64/*.cat",
    "drivers/NetKVM/2k25/amd64/*.inf",
    "drivers/NetKVM/2k25/amd64/*.sys",
    "drivers/NetKVM/2k25/amd64/*.exe",
    "drivers/qxldod/2k25/amd64/*.cat",
    "drivers/qxldod/2k25/amd64/*.inf",
    "drivers/qxldod/2k25/amd64/*.sys",
    "drivers/vioscsi/2k25/amd64/*.cat",
    "drivers/vioscsi/2k25/amd64/*.inf",
    "drivers/vioscsi/2k25/amd64/*.sys",
    "drivers/vioserial/2k25/amd64/*.cat",
    "drivers/vioserial/2k25/amd64/*.inf",
    "drivers/vioserial/2k25/amd64/*.sys",
    "drivers/viostor/2k25/amd64/*.cat",
    "drivers/viostor/2k25/amd64/*.inf",
    "drivers/viostor/2k25/amd64/*.sys",
    "drivers/virtio-win-guest-tools.exe",
    "provision-autounattend.ps1",
    "provision-guest-tools-qemu-kvm.ps1",
    "provision-openssh.ps1",
    "provision-psremoting.ps1",
    "provision-pwsh.ps1",
    "provision-winrm.ps1",
    "tmp/windows-2025-uefi/autounattend.xml",
  ]
  format                   = "qcow2"
  headless                 = true
  net_device               = "virtio-net"
  http_directory           = "."
  iso_url                  = var.iso_url
  iso_checksum             = var.iso_checksum
  shutdown_command         = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator             = "ssh"
  ssh_username             = "vagrant"
  ssh_password             = "vagrant"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
}

source "proxmox-iso" "windows-2025-uefi-amd64" {
  template_name            = "template-windows-2025-uefi"
  template_description     = "See https://github.com/rgl/windows-vagrant"
  tags                     = "windows-2025-uefi;template"
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node
  machine                  = "q35"
  bios                     = "ovmf"
  efi_config {
    efi_storage_pool = "local-lvm"
  }
  cpu_type = "host"
  cores    = 2
  memory   = 4096
  vga {
    type   = "qxl"
    memory = 32
  }
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  scsi_controller = "virtio-scsi-single"
  disks {
    type         = "scsi"
    io_thread    = true
    ssd          = true
    discard      = true
    disk_size    = "${var.disk_size}M"
    storage_pool = "local-lvm"
    format       = "raw"
  }
  boot_iso {
    type             = "ide"
    iso_storage_pool = "local"
    iso_url          = var.iso_url
    iso_checksum     = var.iso_checksum
    iso_download_pve = true
    unmount          = true
  }
  additional_iso_files {
    type             = "ide"
    unmount          = true
    iso_storage_pool = "local"
    cd_label         = "PROVISION"
    cd_files = [
      "drivers/NetKVM/2k25/amd64/*.cat",
      "drivers/NetKVM/2k25/amd64/*.inf",
      "drivers/NetKVM/2k25/amd64/*.sys",
      "drivers/NetKVM/2k25/amd64/*.exe",
      "drivers/qxldod/2k25/amd64/*.cat",
      "drivers/qxldod/2k25/amd64/*.inf",
      "drivers/qxldod/2k25/amd64/*.sys",
      "drivers/vioscsi/2k25/amd64/*.cat",
      "drivers/vioscsi/2k25/amd64/*.inf",
      "drivers/vioscsi/2k25/amd64/*.sys",
      "drivers/vioserial/2k25/amd64/*.cat",
      "drivers/vioserial/2k25/amd64/*.inf",
      "drivers/vioserial/2k25/amd64/*.sys",
      "drivers/viostor/2k25/amd64/*.cat",
      "drivers/viostor/2k25/amd64/*.inf",
      "drivers/viostor/2k25/amd64/*.sys",
      "drivers/virtio-win-guest-tools.exe",
      "provision-autounattend.ps1",
      "provision-guest-tools-qemu-kvm.ps1",
      "provision-openssh.ps1",
      "provision-psremoting.ps1",
      "provision-pwsh.ps1",
      "provision-winrm.ps1",
      "tmp/windows-2025-uefi/autounattend.xml",
    ]
  }
  boot_wait      = "1s"
  boot_command   = ["<up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait>"]
  os             = "win11"
  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "60m"
  http_directory = "."
}

build {
  sources = [
    "source.qemu.windows-2025-uefi-amd64",
    "source.proxmox-iso.windows-2025-uefi-amd64",
    "source.virtualbox-iso.windows-2025-uefi-amd64",
  ]

  provisioner "powershell" {
    use_pwsh = true
    script   = "disable-windows-updates.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "disable-windows-defender.ps1"
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "provision.ps1"
  }

  provisioner "windows-update" {
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "enable-remote-desktop.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "provision-cloudbase-init.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "provision-lock-screen-background.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "eject-media.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "optimize.ps1"
  }

  post-processor "vagrant" {
    except               = ["proxmox-iso.windows-2025-uefi-amd64"]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile-uefi.template"
  }
}
