resource "null_resource" "jitsiInstaller" {
  provisioner "remote-exec" {
    inline = [
      "echo *** Write certificate and key file",
      "echo \"${var.private_key_pem}\" > /etc/ssl/${var.fqdn}.key",
      "chmod 0600 /etc/ssl/${var.fqdn}.key",
      "echo \"${var.fullchain_pem}\" > /etc/ssl/${var.fqdn}.crt",
      "echo *** Upgrade Debian",
      "apt-get update",
      "apt-get upgrade -y",
      "echo *** Import Jitsi repository",
      "apt-get install -y gnupg2",
      "curl https://download.jitsi.org/jitsi-key.gpg.key | apt-key add",
      "echo 'deb https://download.jitsi.org stable/' > /etc/apt/sources.list.d/jitsi-stable.list",
      "echo *** Pre-select Jitsi configuration for silent install",
      "echo 'jitsi-videobridge2 jitsi-videobridge/jvb-hostname string ${var.fqdn}' | debconf-set-selections",
      "echo 'jitsi-meet-web-config jitsi-meet/cert-choice select I want to use my own certificate' | debconf-set-selections",
      "echo 'jitsi-meet-web-config jitsi-meet/cert-path-key string /etc/ssl/${var.fqdn}.key' | debconf-set-selections",
      "echo 'jitsi-meet-web-config jitsi-meet/cert-path-crt string /etc/ssl/${var.fqdn}.crt' | debconf-set-selections",
      "echo *** Upgrade system and install Jitsi",
      "apt-get update",
      "apt-get install -y jitsi-meet",
      "echo *** Reload NGINX to notice certificate changes",
      "systemctl reload nginx",
      "echo *** Configure firewall",
      "echo 'iptables-persistent iptables-persistent/autosave_v4 boolean false' | debconf-set-selections",
      "echo 'iptables-persistent iptables-persistent/autosave_v6 boolean false' | debconf-set-selections",
      "apt-get install -y iptables-persistent",
      "echo \"${local.rules_v4}\" > /etc/iptables/rules.v4",
      "iptables-restore < /etc/iptables/rules.v4",
      "echo \"${local.rules_v6}\" > /etc/iptables/rules.v6",
      "ip6tables-restore < /etc/iptables/rules.v6"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_key_file)
      host        = var.fqdn
      timeout     = "30m"
    }
  }

  triggers = {
    # Run jitsiInstaller again if install script, server or certificate changes.
    issuer = join(";", [local.inline_version, var.server_id, md5(var.fullchain_pem)])
  }
}


locals {
  inline_version = "v0.1.0"

  rules_v4 = <<EOT
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m conntrack --ctstate INVALID -j DROP
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -p tcp -m multiport --dports 22,80,443,4443 -j ACCEPT
-A INPUT -p udp -m udp --dport 10000 -j ACCEPT
COMMIT
EOT

  rules_v6 = <<EOT
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m conntrack --ctstate INVALID -j DROP
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p ipv6-icmp -j ACCEPT
-A INPUT -p tcp -m multiport --dports 22,80,443,4443 -j ACCEPT
-A INPUT -p udp -m udp --dport 10000 -j ACCEPT
COMMIT
EOT
}
