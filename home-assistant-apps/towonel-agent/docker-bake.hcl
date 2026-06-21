target "docker-metadata-action" {}

variable "VERSION" {
  // renovate: datasource=docker depName=codeberg.org/towonel/towonel-agent
  default = "1.0.0"
}

variable "SOURCE" {
  default = "https://codeberg.org/towonel/towonel"
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
  args = {
    VERSION = VERSION
  }
  labels = {
    "org.opencontainers.image.source" = "${SOURCE}"
  }
}

target "image-local" {
  inherits = ["image"]
  output = ["type=docker"]
}

target "image-all" {
  inherits = ["image"]
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
