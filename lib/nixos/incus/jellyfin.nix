# ./lib/nixos/incus/jellyfin.nix
{ pkgs
, hostname
, ...
}:
let
  containerName = "${hostname}-jellyfin";
  traefikContainer = "${hostname}-traefik";
  piholeContainer = "${hostname}-pihole";

  ipAddr = {
    tahi = "172.16.1.210";
  };
  hostIP = ipAddr."${hostname}";

  macAddr = {
    tahi = "10:66:6a:c4:5f:70";
  };
  hostMAC = macAddr."${hostname}";

  traefikIP = "172.16.1.201";

  cloudConfig = pkgs.writeText "jellyfin-cloud-init.yml" ''
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

      - path: /etc/jellyfin/docker-compose.yml
        permissions: '0644'
        content: |
          services:
            jellyfin:
              image: lscr.io/linuxserver/jellyfin:latest
              container_name: jellyfin
              environment:
                - PUID=1000
                - PGID=100
                - TZ=Pacific/Auckland
                - JELLYFIN_PublishedServerUrl=http://${hostIP}:8096
              volumes:
                - /config:/config
                - /data/media/tv:/data/tv:ro
                - /data/media/movies:/data/movies:ro
                - /data/media/music:/data/music:ro
              ports:
                - 8096:8096
                - 7359:7359/udp
                - 1900:1900/udp
              devices:
                - /dev/dri:/dev/dri
              restart: unless-stopped

      - path: /etc/systemd/system/jellyfin-compose.service
        permissions: '0644'
        content: |
          [Unit]
          Description=Jellyfin Docker Compose Service
          After=docker.service network-online.target
          Requires=docker.service

          [Service]
          Type=oneshot
          RemainAfterExit=yes
          WorkingDirectory=/etc/jellyfin
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
      - systemctl enable --now jellyfin-compose
  '';

in
{
  systemd.services."init-${containerName}" = {
    description = "Initialize ${containerName} (Jellyfin Media Server)";
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
              ${pkgs.incus}/bin/incus config device add ${containerName} appdata disk source=/storage/appdata/jellyfin path=/config shift=true
            fi

            # 5. Attach GPU device for VA-API hardware transcoding
            if ! ${pkgs.incus}/bin/incus config device show ${containerName} | grep -q "^gpu:"; then
              ${pkgs.incus}/bin/incus config device add ${containerName} gpu gpu
            fi

            # 6. Apply cloud-init user-data and start container
            ${pkgs.incus}/bin/incus config set ${containerName} user.user-data - < ${cloudConfig}
            ${pkgs.incus}/bin/incus start ${containerName} || true

            # 7. Configure Traefik Reverse Proxy route
            ${pkgs.incus}/bin/incus exec ${traefikContainer} -- mkdir -p /etc/traefik/conf.d
            ${pkgs.incus}/bin/incus exec ${traefikContainer} -- sh -c "cat <<'EOF' > /etc/traefik/conf.d/jellyfin.yml
      http:
        routers:
          jellyfin:
            rule: \"Host(\`jellyfin.lan\`)\"
            service: jellyfin-service
            entryPoints:
              - websecure
            tls:
              certResolver: stepca

        services:
          jellyfin-service:
            loadBalancer:
              servers:
                - url: \"http://${hostIP}:8096\"
      EOF"

            # 8. Configure Pi-hole Local DNS
            ${pkgs.incus}/bin/incus exec ${piholeContainer} -- sh -c "
              if ! grep -q 'jellyfin.lan' /etc/pihole/custom.list 2>/dev/null; then
                echo '${traefikIP} jellyfin.lan' >> /etc/pihole/custom.list
                pihole reloaddns || true
              fi
            "

            # 9. Reload Traefik config
            ${pkgs.incus}/bin/incus exec ${traefikContainer} -- killall -HUP traefik || true
    '';
  };
}
