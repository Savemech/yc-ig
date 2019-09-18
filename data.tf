data "template_file" "init" {
  template = "${file("cloud-init.tmpl")}"
}
