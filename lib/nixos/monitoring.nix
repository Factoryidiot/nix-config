# ./lib/nixos/monitoring.nix
{ config, pkgs, lib, ... }:
{
  # 1. Prometheus Metrics Engine & Scrapers
  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "0.0.0.0";
    retentionTime = "30d";

    # Native Exporters on host
    exporters = {
      node = {
        enable = true;
        port = 9100;
        listenAddress = "127.0.0.1";
        enabledCollectors = [ "systemd" ];
      };

      zfs = {
        enable = true;
        port = 9134;
        listenAddress = "127.0.0.1";
        pools = [ "tank" ];
      };

      smartctl = {
        enable = true;
        port = 9633;
        listenAddress = "127.0.0.1";
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "127.0.0.1:9100" ];
            labels = { instance = "tahi"; };
          }
        ];
      }
      {
        job_name = "zfs";
        static_configs = [
          {
            targets = [ "127.0.0.1:9134" ];
            labels = { instance = "tahi"; };
          }
        ];
      }
      {
        job_name = "smartctl";
        static_configs = [
          {
            targets = [ "127.0.0.1:9633" ];
            labels = { instance = "tahi"; };
          }
        ];
      }
      {
        job_name = "incus";
        metrics_path = "/1.0/metrics";
        scheme = "https";
        tls_config = {
          insecure_skip_verify = true;
        };
        static_configs = [
          {
            targets = [ "127.0.0.1:9101" ];
            labels = { instance = "tahi"; };
          }
        ];
      }
    ];
  };

  # 2. Grafana Visualization & Dashboards
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "grafana.lan";
        root_url = "https://grafana.lan/";
      };
      security = {
        admin_user = "admin";
        secret_key = "$__file{/var/lib/grafana/secret_key}";
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }
      ];
    };
  };

  systemd.services.grafana.preStart = lib.mkBefore ''
    if [ ! -f /var/lib/grafana/secret_key ]; then
      mkdir -p /var/lib/grafana
      ${pkgs.openssl}/bin/openssl rand -base64 32 > /var/lib/grafana/secret_key
      chmod 400 /var/lib/grafana/secret_key
    fi
  '';

  # 3. Homepage Application Dashboard
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    environmentFiles = [ "/persistent/var/lib/homepage/homepage.env" ];

    settings = {
      title = "Tahi Homelab";
      theme = "dark";
      color = "zinc";
      layout = {
        "Media & Automation" = {
          style = "row";
          columns = 4;
        };
        "Network & Infrastructure" = {
          style = "row";
          columns = 4;
        };
        "Monitoring & Observability" = {
          style = "row";
          columns = 2;
        };
      };
    };

    widgets = [
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
        };
      }
      {
        resources = {
          cpu = true;
          memory = true;
          cputemp = true;
          disk = "/storage/data";
        };
      }
    ];

    services = [
      {
        "Media & Automation" = [
          {
            "Jellyfin" = {
              icon = "jellyfin.svg";
              href = "https://jellyfin.lan";
              description = "Media Streaming Server";
              ping = "http://172.16.1.210:8096";
            };
          }
          {
            "SABnzbd" = {
              icon = "sabnzbd.svg";
              href = "https://sabnzbd.lan";
              description = "Usenet Downloader";
              widget = {
                type = "sabnzbd";
                url = "http://172.16.1.211:8080";
                key = "{{HOMEPAGE_VAR_SABNZBD_KEY}}";
              };
            };
          }
          {
            "Sonarr" = {
              icon = "sonarr.svg";
              href = "https://sonarr.lan";
              description = "TV Series Automation";
              widget = {
                type = "sonarr";
                url = "http://172.16.1.211:8989";
                key = "{{HOMEPAGE_VAR_SONARR_KEY}}";
              };
            };
          }
          {
            "Radarr" = {
              icon = "radarr.svg";
              href = "https://radarr.lan";
              description = "Movie Automation";
              widget = {
                type = "radarr";
                url = "http://172.16.1.211:7878";
                key = "{{HOMEPAGE_VAR_RADARR_KEY}}";
              };
            };
          }
          {
            "Prowlarr" = {
              icon = "prowlarr.svg";
              href = "https://prowlarr.lan";
              description = "Indexer Manager";
              widget = {
                type = "prowlarr";
                url = "http://172.16.1.211:9696";
                key = "{{HOMEPAGE_VAR_PROWLARR_KEY}}";
              };
            };
          }
          {
            "Bazarr" = {
              icon = "bazarr.svg";
              href = "https://bazarr.lan";
              description = "Subtitle Management";
              ping = "http://172.16.1.211:6767";
            };
          }
          {
            "qBittorrent" = {
              icon = "qbittorrent.svg";
              href = "https://qbit.lan";
              description = "Torrent Client";
              ping = "http://172.16.1.211:8085";
            };
          }
        ];
      }
      {
        "Network & Infrastructure" = [
          {
            "Pi-hole" = {
              icon = "pi-hole.svg";
              href = "https://pihole.lan";
              description = "DNS Ad-blocking";
              ping = "http://172.16.1.202";
            };
          }
          {
            "Incus Console" = {
              icon = "incus.svg";
              href = "https://incus.lan";
              description = "Container & VM Virtualization";
              ping = "https://172.16.1.200:8443";
            };
          }
          {
            "Traefik" = {
              icon = "traefik.svg";
              href = "https://traefik.lan";
              description = "Edge Routing & TLS";
              ping = "http://172.16.1.201:8080";
            };
          }
          {
            "Step-CA" = {
              icon = "smallstep.svg";
              href = "https://ca.lan";
              description = "Internal Certificate Authority";
              ping = "https://172.16.1.204";
            };
          }
        ];
      }
      {
        "Monitoring & Observability" = [
          {
            "Grafana" = {
              icon = "grafana.svg";
              href = "https://grafana.lan";
              description = "Hardware, ZFS & Telemetry Dashboards";
              ping = "http://127.0.0.1:3000";
            };
          }
          {
            "Prometheus" = {
              icon = "prometheus.svg";
              href = "http://172.16.1.200:9090";
              description = "Metrics Time-Series Database";
              ping = "http://127.0.0.1:9090";
            };
          }
        ];
      }
    ];
  };

  # Open firewall ports for Grafana and Homepage
  networking.firewall.allowedTCPPorts = [
    3000 # Grafana
    8082 # Homepage
    9090 # Prometheus
  ];
}
