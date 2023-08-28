terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "hcloud_ssh_key" "jenkins" {
  name       = "jenkins"
  public_key = file(var.hcloud_ssh_key)
}

resource "hcloud_server" "jenkins" {
  name        = "jenkins-server"
  server_type = "cx11"
  image       = "ubuntu-20.04"
  location    = "fsn1"
  ssh_keys    = [hcloud_ssh_key.jenkins.id]
}

resource "cloudflare_record" "jenkins_dns" {
  depends_on  = [hcloud_server.jenkins]
  zone_id     = var.cloudflare_zone_id
  name        = var.domain_name
  value       = hcloud_server.jenkins.ipv4_address
  type        = "A"
  ttl         = 1
  proxied     = false
}

resource "null_resource" "jenkins_nginx_setup" {
  depends_on = [cloudflare_record.jenkins_dns]

  provisioner "file" {
    source      = "install_jenkins_nginx.sh"
    destination = "/tmp/install_jenkins_nginx.sh"
    
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.hcloud_ssh_key_private)
      host        = hcloud_server.jenkins.ipv4_address
    }
  }

  provisioner "file" {
    source      = "jenkins_nginx.conf"
    destination = "/tmp/jenkins_nginx.conf"
    
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.hcloud_ssh_key_private)
      host        = hcloud_server.jenkins.ipv4_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_jenkins_nginx.sh",
      "export DOMAIN_NAME='${var.domain_name}'",
      "/tmp/install_jenkins_nginx.sh"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.hcloud_ssh_key_private)
      host        = hcloud_server.jenkins.ipv4_address
    }
  }
}

resource "null_resource" "certbot_setup" {
  depends_on = [null_resource.jenkins_nginx_setup]

  provisioner "file" {
    source      = "setup_certbot.sh"
    destination = "/tmp/setup_certbot.sh"
    
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.hcloud_ssh_key_private)
      host        = hcloud_server.jenkins.ipv4_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_certbot.sh",
      "export DOMAIN_NAME='${var.domain_name}'",
      "export ADMIN_EMAIL='${var.admin_email}'",
      "/tmp/setup_certbot.sh"
    ]
    
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.hcloud_ssh_key_private)
      host        = hcloud_server.jenkins.ipv4_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Initial Admin Password for Jenkins:'",
      "cat /var/lib/jenkins/secrets/initialAdminPassword"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.hcloud_ssh_key_private)
      host        = hcloud_server.jenkins.ipv4_address
    }
  }
}
