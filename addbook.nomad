job "addbook" {
  region = "uk"
  type = "batch"
  parameterized {
    payload       = "forbidden"
    meta_required = ["ISBN"]
  }

  update {
    stagger = "5s"
    max_parallel = 1
  }
  group "batch" {
    count = 1
    task "date" {
      artifact {
        source      = "git::https://github.com/ncorrare/library"
      }
      vault {
        policies = ["library"]

        change_mode   = "signal"
        change_signal = "SIGUSR1"
      }
      driver = "raw_exec"
      config {
        command = "ruby"
        args = ["addbook.rb", "${NOMAD_META_ISBN}"]
      }
      resources {
        cpu = 100 # Mhz
        memory = 128 # MB
        network {
          mbits = 1
        }
      }
    }
  }
}
