job "addbook" {
  region = "uk"
  type = "batch"
  datacenters = ["dc1"]
  parameterized {
    payload       = "forbidden"
    meta_required = ["ISBN"]
  }

  group "batch" {
    count = 1
    task "createbook" {
      env {
        CONSUL_HTTP_ADDR = "http://${attr.unique.network.ip-address}:8500"
        NOMAD_ADDR = "http://${attr.unique.network.ip-address}:8500"
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
        image = "ncorrare/library:release-0.1.18"
        command = "ruby"
        args = ["addbook.rb", "${NOMAD_META_ISBN}"]
      }
      resources {
        cpu = 100 # Mhz
        memory = 128 # MB
        network {
          mbits = 10
        }
      }
    }
  }
}
