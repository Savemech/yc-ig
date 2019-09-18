resource "random_id" "getrandom" {
  byte_length = 4
}
resource "yandex_iam_service_account" "appname-ig-sa" {
  name        = "appname-ig-sa"
  description = "service account to manage appname_ig"
}
resource "yandex_resourcemanager_folder_iam_binding" "appname-ig-role-iam-binding" {
  folder_id = "${var.folder_id}"
  role      = "editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.appname-ig-sa.id}",
  ]
  depends_on = ["yandex_iam_service_account.appname-ig-sa"]

}

variable "cluster_size" {
  default = 3
}

resource "yandex_compute_instance_group" "appname-ig" {
  #  name               = "test-ig"
  name               = "appname-ig-${lower(random_id.getrandom.hex)}"
  service_account_id = "${yandex_iam_service_account.appname-ig-sa.id}"
  folder_id          = "${var.folder_id}"

  instance_template {
    #    platform_id = "standard-v2"
    platform_id = "standard-v1"
    resources {
      core_fraction = 5
      memory        = 1
      cores         = 1
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "${var.image_id}"
        size     = 10
      }
    }
    network_interface {
      network_id = "${yandex_vpc_network.network.id}"
      subnet_ids = "${yandex_vpc_subnet.subnet.*.id}"
      nat        = true
    }

    labels = {
      lastupdate = "${var.packer_buildtime}"
      #      skip_update_ssh_keys = true
    }
    metadata = {
      # foo       = "bar"
      # ssh-keys  = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
      user-data = "${data.template_file.init.rendered}"

    }
  }

  scale_policy {
    fixed_scale {
      size = "${var.cluster_size}"
    }
  }

  allocation_policy {
    #    zones = ["ru-central1-a"]
    zones = "${var.zones}"
  }

  deploy_policy {
    max_unavailable = "${var.cluster_size}"
    max_creating    = "${var.cluster_size}"
    max_expansion   = "${var.cluster_size}"
    max_deleting    = "${var.cluster_size}"
  }

  health_check {
    interval            = "2"
    timeout             = "1"
    healthy_threshold   = "5"
    unhealthy_threshold = "5"
    #    tcp_options         = "8080"

    http_options {
      port = "8080"
      path = "/"
    }




  }


  depends_on = ["yandex_resourcemanager_folder_iam_binding.appname-ig-role-iam-binding", "yandex_iam_service_account.appname-ig-sa"]
}

output "ig-id" {
  value = yandex_compute_instance_group.appname-ig.id
}




# resource "yandex_lb_target_group" "appname-tg" {
#   name      = "appname-tg"
#   region_id = "${var.zones}"

#   target {
#     subnet_id = "${yandex_vpc_subnet.subnet.*.id}"
#     address   = "${yandex_compute_instance_group.appname-ig.network_interface.0.ip_address}"
#   }

#   # target {
#   #   subnet_id = "${yandex_vpc_subnet.my-subnet.id}"
#   #   address   = "${yandex_compute_instance.my-instance-2.network_interface.0.ip_address}"
#   # }

#   # target {
#   #   subnet_id = "${yandex_vpc_subnet.my-subnet.id}"
#   #   address   = "${yandex_compute_instance.my-instance-2.network_interface.0.ip_address}"
#   # }
# }






