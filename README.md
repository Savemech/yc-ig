# yc-ig-packer-tf
## Pre requisits 
As using any Hashicorp software you're presumably read and agree with following licenses [terraform](https://github.com/hashicorp/terraform/blob/master/LICENSE) [packer](https://github.com/hashicorp/packer/blob/master/LICENSE)


In this example we would:
* Build image with some code to use
  * Based on Ubuntu 18.04



Now set some variables to work with packer and then terraform:
```bash
unset IMAGE_FAMILY
unset PACKER_APPNAME
unset PACKER_BUILDTIME
unset IMAGE_NAME
unset TF_VAR_packer_buildtime
unset TF_VAR_image_id
unset TF_VAR_image_name

export IMAGE_FAMILY=ubuntu-1804
export PACKER_APPNAME=dwno
export PACKER_BUILDTIME=$(date +%Y-%m-%d--%H-%M)
export IMAGE_NAME=${IMAGE_FAMILY}-${PACKER_APPNAME}-${PACKER_BUILDTIME}
```

Build image:
```bash
packer build -machine-readable image.json | tee output

export TF_VAR_packer_buildtime=${PACKER_BUILDTIME}
export TF_VAR_image_id=$(grep -e "yandex,artifact,0,id," output | cut -d"," -f6)
export TF_VAR_image_name=${IMAGE_NAME}
```



Create/Update:
* Create [Service account](https://cloud.yandex.com/docs/iam/concepts/users/service-accounts)
* Create [VPC](https://cloud.yandex.com/docs/vpc/concepts/)
* Create 3 subnets in diffirent [(Availability zones(AZ))](https://cloud.yandex.com/docs/overview/concepts/geo-scope)
* Deploy instance group started at 3 nodes all in diffirent AZ


```bash
tf output -json | jq -r '.[]| .value'
```


Now to the target group part
```bash
yc compute ig  --id $(tf output -json | jq -r '.[]| .value') list-instances --format json | jq -r '.[].network_interfaces  | .[].primary_v4_address  | .address'
```

```
cat terraform.tfstate | jq -r '.modules[0].resources | map(select(.type == "google_compute_instance")) | map([.primary.id, " ansible_ssh_host=", .primary.attributes["network_interface.0.access_config.0.nat_ip"]] | join("")) | sort | .[]'
```



Terraform part

Watch out, and you need sane defaults for this block, in my case for testing, is OK to some application unavailability

```terraform
 deploy_policy {
    max_unavailable = "${var.cluster_size}"
    max_creating    = "${var.cluster_size}"
    max_expansion   = "${var.cluster_size}"
    max_deleting    = "${var.cluster_size}"
  }
```

