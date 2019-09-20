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
  load_balancer {
    target_group_labels = {
      service = "appname"
    }
    target_group_name = "appname"
  }



  depends_on = ["yandex_resourcemanager_folder_iam_binding.appname-ig-role-iam-binding", "yandex_iam_service_account.appname-ig-sa"]
}

output "ig-id" {
  value = yandex_compute_instance_group.appname-ig.id
}

# output "listener-address" {
#   value = yandex_lb_network_load_balancer.appname-lb.listener
#   #yandex_lb_network_load_balancer.appname-lb.listener.*.external_address_spec.address
#   #yandex_lb_network_load_balancer.appname-lb.listener.*.address
# }



resource "yandex_lb_network_load_balancer" "appname-lb" {
  name = "appname-lb-${lower(random_id.getrandom.hex)}"

  listener {
    name = "appname-listener-8080-${lower(random_id.getrandom.hex)}"
    port = 8080
    external_address_spec {
      ip_version = "ipv4"
    }

  }


  attached_target_group {
    target_group_id = "${yandex_compute_instance_group.appname-ig.load_balancer.0.target_group_id}"

    healthcheck {
      name = "http"
      http_options {
        port = 8080
        path = "/"
      }
    }
  }
}
