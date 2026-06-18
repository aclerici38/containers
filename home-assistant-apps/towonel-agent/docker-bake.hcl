target "docker-metadata-action" {}

# Upstream agent release. This is the tag the prebuilt image is published under
# (read by CI's app-options) and the version config.yaml pulls. The Dockerfile pins
# the same upstream release by digest; Renovate keeps both current.
variable "VERSION" {
  // renovate: datasource=docker depName=codeberg.org/towonel/towonel-agent
  default = "0.2.2"
}

variable "SOURCE" {
  default = "https://codeberg.org/towonel/towonel"
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
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
