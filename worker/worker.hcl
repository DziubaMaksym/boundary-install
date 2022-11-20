listener "tcp" {
  purpose     = "proxy"
  tls_disable = false
  address     = "0.0.0.0"
}

worker {
  # Name attr must be unique
  name        = "worker-${count.index}"
  description = "A default worker created"
  public_addr = "${worker.public.address}"
  controllers = [
    "${controller.private.ip}"
  ]
}

# must be same key as used on controller config
kms "gcpckms" {
  purpose    = "worker-auth"
  project    = "${project}"
  region     = "${region}"
  key_ring   = "${key_ring}"
  crypto_key = "${crypto_key}"
}