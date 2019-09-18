resource "yandex_vpc_network" "network" {
  name = "app-ig-network"
}

resource "yandex_vpc_subnet" "subnet" {
  count          = "${var.cluster_size > length(var.zones) ? length(var.zones) : var.cluster_size}"
  name           = "app-ig-subnet-${count.index}"
  zone           = "${element(var.zones, count.index)}"
  network_id     = "${yandex_vpc_network.network.id}"
  v4_cidr_blocks = ["172.16.${count.index}.0/24"]
  depends_on     = ["var.cluster_size", "yandex_vpc_network.network", "var.zones"]
}

variable "image_id" {}
variable "packer_buildtime" {}

variable "zones" {
  description = "Yandex Cloud default Zone for provisoned resources"
  default     = ["ru-central1-a", "ru-central1-b", "ru-central1-c"]
}
