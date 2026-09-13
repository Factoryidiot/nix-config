{ pkgs
, hostname
, ...
}:
let
  containerName = "${hostname}-pihole";
  traefikContainer = "${hostname}-traefik";

  unboundIP = "172.16.1.203";

  ipAddr = {
    #Mmanual configuration
    tahi = "172.16.1.202";
  };
  hostIP = ipAddr."${hostname}";

  macAddr = {
    #Manual configuration
    tahi = "10:66:6a:bb:eb:ec";
  };
  hostMAC = macAddr."${hostname}";

  cloudConfig = pkgs.writeText "cloud-init.yml" ''
    #cloud-config
    packages:
      - curl
      - debconf-utils

    runcmd:
      - |
        cat <<EOF > /etc/systemd/network/10-cloud-init-eth0.network
        [Match]
        Name=eth0
        [Network]
        DHCP=ipv4
        [DHCPv4]
        ClientIdentifier=mac
        EOF
      - systemctl restart systemd-networkd

      - until ping -c 1 pi-hole.net; do sleep 2; done
      - curl -L https://install.pi-hole.net | bash /dev/stdin --unattended

      - systemctl stop dhcpcd || true
      - systemctl disable dhcpcd || true
  '';

in
{
  systemd.services."init-${containerName}" = {
    description = "Initialize ${containerName} and link to Traefik";
    # Ensure this runs after Traefik's own init service
    after = [ "incus.service" "init-${traefikContainer}.service" ];
    requires = [ "incus.socket" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
            until ${pkgs.incus}/bin/incus info >/dev/null 2>&1; do sleep 1; done

            if ! ${pkgs.incus}/bin/incus list --format csv -c n | grep -qx "${containerName}"; then
              ${pkgs.incus}/bin/incus init images:debian/12/cloud ${containerName} --profile default
            fi

            ${pkgs.incus}/bin/incus config set ${containerName} volatile.eth0.hwaddr ${hostMAC}

            ${pkgs.incus}/bin/incus config set ${containerName} user.user-data - < ${cloudConfig}
            ${pkgs.incus}/bin/incus start ${containerName} || true

            # --- WAIT FOR INSTALLATION ---
            echo "Waiting for Pi-hole installation to create the 'pihole' user..."
            iteration=0
            until ${pkgs.incus}/bin/incus exec ${containerName} -- id -u pihole >/dev/null 2>&1; do
              iteration=$((iteration+1))
              if [ $iteration -gt 300 ]; then
                echo "Pi-hole installation timed out after 5 minutes."
                exit 1
              fi
              sleep 2
            done

            ${pkgs.incus}/bin/incus exec ${traefikContainer} -- mkdir -p /etc/traefik/conf.d

            ${pkgs.incus}/bin/incus exec ${traefikContainer} -- sh -c "cat <<'EOF' > /etc/traefik/conf.d/pihole.yml
      http:
        routers:
          pihole:
            rule: \"Host(\`pihole.lan\`)\"
            service: pihole-service
            entryPoints:
              - websecure
            tls:
              certResolver: stepca
            middlewares:
              - pihole-redirect

        middlewares:
          pihole-redirect:
            redirectRegex:
              regex: \"^https://pihole.lan/$\"
              replacement: \"https://pihole.lan/admin/\"

        services:
          pihole-service:
            loadBalancer:
              servers:
                - url: \"http://${hostIP}\"
      EOF"

            ${pkgs.incus}/bin/incus exec ${containerName} -- mkdir -p /etc/pihole

            ${pkgs.incus}/bin/incus exec ${containerName} -- sh -c "cat <<'EOF' > /etc/pihole/setupVars.conf
      PIHOLE_INTERFACE=eth0
      PIHOLE_DNS_1=${unboundIP}#53
      PIHOLE_DNS_2=no
      DNS_FQDN_REQUIRED=true
      DNS_BOGUS_PRIV=true
      DNSSEC=true
      QUERY_LOGGING=true
      INSTALL_WEB_INTERFACE=true
      INSTALL_WEB_SERVER=true
      LIGHTTPD_ENABLED=true
      CACHE_SIZE=10000
      EOF"

            ${pkgs.incus}/bin/incus exec ${containerName} -- chown -R pihole:pihole /etc/pihole

            # Configure wildcard .lan DNS resolution to Traefik proxy
            ${pkgs.incus}/bin/incus exec ${containerName} -- pihole-FTL --config misc.dnsmasq_lines '["address=/lan/172.16.1.201"]' || true

            ${pkgs.incus}/bin/incus exec ${containerName} -- pihole restartdns

            ${pkgs.incus}/bin/incus exec ${traefikContainer} -- killall -HUP traefik || true

    '';
  };
}
