target "docker-metadata-action" {}

variable "VERSION" {
  // renovate: datasource=docker depName=caddy
  default = "2.11.4"
}

variable "CLOUDFLARE_VERSION" {
  // renovate: datasource=github-tags depName=caddy-dns/cloudflare
  default = "v0.2.4"
}

variable "L4_VERSION" {
  // renovate: datasource=github-releases depName=mholt/caddy-l4
  default = "v0.1.1"
}

variable "SOURCE" {
  default = "https://github.com/caddyserver/caddy"
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
  args = {
    VERSION = "${VERSION}"
    L4_VERSION = "${L4_VERSION}"
    CLOUDFLARE_VERSION = "${CLOUDFLARE_VERSION}"
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