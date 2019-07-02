job "library" {
  region = "uk"
  type = "service"
  datacenters = ["dc1"]
  update {
    stagger      = "30s"
    max_parallel = 2
  }
  group "api" {
    count = 3
    task "web" {
      env {
        CONSUL_HTTP_ADDR = "http://${attr.unique.network.ip-address}:8500"
        VAULT_ADDR = "https://vault.stn.corrarello.net"
        VAULT_SKIP_VERIFY = "true"
      }
      vault {
        policies = ["library"]

        change_mode   = "signal"
        change_signal = "SIGUSR1"
      }
      driver = "docker"
      config {
        image = "ncorrare/library:release-0.1.8"
        command = "ruby"
        args = ["main.rb"]
      }
      service {

        port = "http"

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
      resources {
        cpu = 500 # Mhz
        memory = 512 # MB
        network {
          mbits = 50
          port "http" {}
        }
      }
    }
  }
}
