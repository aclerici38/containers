target "docker-metadata-action" {}

variable "VERSION" {
  // renovate: datasource=alpine depName=smartmontools versioning=apk
  default = "7.5-r0"
}

variable "SOURCE" {
  default = "https://github.com/smartmontools/smartmontools"
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
  args = {
    VERSION = "${VERSION}"
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