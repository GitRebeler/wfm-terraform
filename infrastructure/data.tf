data "template_file" "infra_jason_output" {
  template = "${file("${path.module}/infra.json.tftpl")}"

#   vars = {
#     consul_address = "${aws_instance.consul.private_ip}"
#   }
    vars = {
      vm_web1_name          = local.vm_web1_name
      vm_web2_name          = local.vm_web2_name
      vm_app1_name          = local.vm_app1_name
      vm_app2_name          = local.vm_app2_name
      vm_acs_name           = local.vm_acs_name
      vm_db_name            = local.vm_db_name
      vm-size-app           = var.vm-size-app
      vm-size-web           = var.vm-size-web
      vm-size-acs           = var.vm-size-acs
      db-size               = var.db-size
      clientcode            = var.clientcode
      client                = var.client
      nice_dr               = var.nice-dr
      nice-environment      = var.nice-environment
      nice-instanceid       = var.nice-instanceid
      svc                   = var.svc
      loc                   = var.loc
      wfm-url               = var.wfm-url
      nde-url               = var.nde-url
    }
}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "/etc/nca/infra.json"
    content      = "${data.template_file.infra_jason_output.rendered}"
  }
  part {
    filename     = "/etc/nca/bootstrap-azure.sh"
    content      = "${file("${path.module}/setup.sh")}"
  }
}