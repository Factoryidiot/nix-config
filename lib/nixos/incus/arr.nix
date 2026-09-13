# ./lib/nixos/incus/arr.nix
{ pkgs
, hostname
, ...
}:
let
  containerName = "${hostname}-arr";
  traefikContainer = "${hostname}-traefik";
  piholeContainer = "${hostname}-pihole";

  ipAddr = {
    tahi = "172.16.1.211";
  };
  hostIP = ipAddr."${hostname}";

  macAddr = {
    tahi = "10:66:6a:c4:5f:71";
  };
  hostMAC = macAddr."${hostname}";

  traefikIP = "172.16.1.201";

  cloudConfig = pkgs.writeText "arr-cloud-init.yml" ''
    #cloud-config
    packages:
      - curl
      - ca-certificates
      - gnupg
      - docker.io

    write_files:
      - path: /etc/systemd/network/10-cloud-init-eth0.network
        permissions: '0644'
        content: |
          [Match]
          Name=eth0
          [Network]
          Address=${hostIP}/24
          Gateway=172.16.1.1
          DNS=172.16.1.202
          DNS=172.16.1.203

      - path: /etc/arr/docker-compose.yml
        permissions: '0644'
        content: |
          services:
            sabnzbd:
              image: lscr.io/linuxserver/sabnzbd:latest
              container_name: sabnzbd
              environment:
                - PUID=1000
                - PGID=100
                - TZ=Pacific/Auckland
              volumes:
                - /appdata/sabnzbd:/config
                - /data/usenet:/data/usenet
                - /data/media:/data/media
              ports:
                - 8080:8080
              restart: unless-stopped

            prowlarr:
              image: lscr.io/linuxserver/prowlarr:latest
              container_name: prowlarr
              environment:
                - PUID=1000
                - PGID=100
                - TZ=Pacific/Auckland
              volumes:
                - /appdata/prowlarr:/config
              ports:
                - 9696:9696
              restart: unless-stopped

            sonarr:
              image: lscr.io/linuxserver/sonarr:latest
              container_name: sonarr
              environment:
                - PUID=1000
                - PGID=100
                - TZ=Pacific/Auckland
              volumes:
                - /appdata/sonarr:/config
                - /data:/data
              ports:
                - 8989:8989
              restart: unless-stopped

            radarr:
              image: lscr.io/linuxserver/radarr:latest
              container_name: radarr
              environment:
                - PUID=1000
                - PGID=100
                - TZ=Pacific/Auckland
              volumes:
                - /appdata/radarr:/config
                - /data:/data
              ports:
                - 7878:7878
              restart: unless-stopped

            bazarr:
              image: lscr.io/linuxserver/bazarr:latest
              container_name: bazarr
              environment:
                - PUID=1000
                - PGID=100
                - TZ=Pacific/Auckland
              volumes:
                - /appdata/bazarr:/config
                - /data/media/tv:/tv
                - /data/media/movies:/movies
              ports:
                - 6767:6767
              restart: unless-stopped

            qbittorrent:
              image: lscr.io/linuxserver/qbittorrent:latest
              container_name: qbittorrent
              environment:
                - PUID=1000
                - PGID=100
                - TZ=Pacific/Auckland
                - WEBUI_PORT=8085
                - TORRENTING_PORT=6881
              volumes:
                - /appdata/qbittorrent:/config
                - /data/torrents:/data/torrents
              ports:
                - 8085:8085
                - 6881:6881
                - 6881:6881/udp
              restart: unless-stopped

      - path: /etc/systemd/system/arr-compose.service
        permissions: '0644'
        content: |
          [Unit]
          Description=Arr Stack Docker Compose Service
          After=docker.service network-online.target
          Requires=docker.service

          [Service]
          Type=oneshot
          RemainAfterExit=yes
          WorkingDirectory=/etc/arr
          ExecStart=/usr/local/bin/docker-compose up -d
          ExecStop=/usr/local/bin/docker-compose down

          [Install]
          WantedBy=multi-user.target

    runcmd:
      - |
        # Download Docker Compose CLI plugin
        mkdir -p /usr/local/lib/docker/cli-plugins /usr/local/bin
        curl -sSL https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        ln -sf /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
      - systemctl restart systemd-networkd
      - systemctl daemon-reload
      - systemctl enable --now docker
      - systemctl enable --now arr-compose
  '';

in
{
  systemd.services."init-${containerName}" = {
    description = "Initialize ${containerName} (*arr & download automation stack)";
    after = [ "incus.service" "incus.socket" "init-${traefikContainer}.service" "zfs-mount.service" ];
    requires = [ "incus.socket" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
            # 1. Wait for Incus daemon
            until ${pkgs.incus}/bin/incus info >/dev/null 2>&1; do sleep 1; done

            # 2. Create container if missing
            if ! ${pkgs.incus}/bin/incus list --format csv -c n | grep -qx "${containerName}"; then
              ${pkgs.incus}/bin/incus init images:debian/12/cloud ${containerName} --profile default
            fi

            # 3. Configure hardware MAC and nesting
            ${pkgs.incus}/bin/incus config set ${containerName} volatile.eth0.hwaddr ${hostMAC}
            ${pkgs.incus}/bin/incus config set ${containerName} security.nesting true

            # 4. Attach ZFS storage devices (with kernel idmap shift)
            if ! ${pkgs.incus}/bin/incus config device show ${containerName} | grep -q "^data:"; then
              ${pkgs.incus}/bin/incus config device add ${containerName} data disk source=/storage/data path=/data shift=true
            fi

            if ! ${pkgs.incus}/bin/incus config device show ${containerName} | grep -q "^appdata:"; then
              ${pkgs.incus}/bin/incus config device add ${containerName} appdata disk source=/storage/appdata path=/appdata shift=true
            fi

            # 5. Apply cloud-init user-data and start container
            ${pkgs.incus}/bin/incus config set ${containerName} user.user-data - < ${cloudConfig}
            ${pkgs.incus}/bin/incus start ${containerName} || true

            # 6. Configure Traefik Reverse Proxy routes
            ${pkgs.incus}/bin/incus exec ${traefikContainer} -- mkdir -p /etc/traefik/conf.d
            ${pkgs.incus}/bin/incus exec ${traefikContainer} -- sh -c "cat <<'EOF' > /etc/traefik/conf.d/arr.yml
      http:
        routers:
          sabnzbd:
            rule: \"Host(\`sabnzbd.lan\`)\"
            service: sabnzbd-service
            entryPoints:
              - websecure
            tls:
              certResolver: stepca

          sonarr:
            rule: \"Host(\`sonarr.lan\`)\"
            service: sonarr-service
            entryPoints:
              - websecure
            tls:
              certResolver: stepca

          radarr:
            rule: \"Host(\`radarr.lan\`)\"
            service: radarr-service
            entryPoints:
              - websecure
            tls:
              certResolver: stepca

          prowlarr:
            rule: \"Host(\`prowlarr.lan\`)\"
            service: prowlarr-service
            entryPoints:
              - websecure
            tls:
              certResolver: stepca

          bazarr:
            rule: \"Host(\`bazarr.lan\`)\"
            service: bazarr-service
            entryPoints:
              - websecure
            tls:
              certResolver: stepca

          qbit:
            rule: \"Host(\`qbit.lan\`)\"
            service: qbit-service
            entryPoints:
              - websecure
            tls:
              certResolver: stepca

        services:
          sabnzbd-service:
            loadBalancer:
              servers:
                - url: \"http://${hostIP}:8080\"
          sonarr-service:
            loadBalancer:
              servers:
                - url: \"http://${hostIP}:8989\"
          radarr-service:
            loadBalancer:
              servers:
                - url: \"http://${hostIP}:7878\"
          prowlarr-service:
            loadBalancer:
              servers:
                - url: \"http://${hostIP}:9696\"
          bazarr-service:
            loadBalancer:
              servers:
                - url: \"http://${hostIP}:6767\"
          qbit-service:
            loadBalancer:
              servers:
                - url: \"http://${hostIP}:8085\"
      EOF"

            # 7. Configure Pi-hole Local DNS for all arr domains
            ${pkgs.incus}/bin/incus exec ${piholeContainer} -- sh -c "
              changed=0
              for domain in sabnzbd.lan sonarr.lan radarr.lan prowlarr.lan bazarr.lan qbit.lan; do
                if ! grep -q \"\$domain\" /etc/pihole/custom.list 2>/dev/null; then
                  echo '${traefikIP} '\"\$domain\" >> /etc/pihole/custom.list
                  changed=1
                fi
              done
              if [ \"\$changed\" -eq 1 ]; then
                pihole reloaddns || true
              fi
            "

            # 8. Reload Traefik config
            ${pkgs.incus}/bin/incus exec ${traefikContainer} -- killall -HUP traefik || true
    '';
  };
}
