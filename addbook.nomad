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
      artifact {
        source      = "git::https://github.com/ncorrare/library.git"
        options = {
          depth = 1
        }
      }
      vault {
        policies = ["library"]

        change_mode   = "signal"
        change_signal = "SIGUSR1"
      }
      driver = "exec"
      config {
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
