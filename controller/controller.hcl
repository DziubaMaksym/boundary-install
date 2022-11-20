# Disable memory lock: https://www.man7.org/linux/man-pages/man2/mlock.2.html
disable_mlock = true

# Controller configuration block
controller {
  # This name attr must be unique!
  name = "controller-main"
  # Description of this controller
  description = "A controller!"
  database {
    url = "postgresql://${DB_USER}:${DBPASSWD}@${DB_IP}/boundary"
  }
}

# API listener configuration block
listener "tcp" {
  # Should be the address of the NIC that the controller server will be reached on
  address = "0.0.0.0:9200"
  # The purpose of this listener block
  purpose = "api"
  # Should be enabled for production installs
  tls_disable = true
  # Enable CORS for the Admin UI
  cors_enabled         = true
  cors_allowed_origins = ["*"]
}

# Data-plane listener configuration block (used for worker coordination)
listener "tcp" {
  # Should be the IP of the NIC that the worker will connect on
  address = "${controller.private.ip}:9201"
  # The purpose of this listener
  purpose = "cluster"
  # Should be enabled for production installs
  tls_disable = true
}

# Root KMS configuration block: this is the root key for Boundary
# Use a production KMS such as AWS KMS in production installs
kms "gcpckms" {
  purpose    = "root"
  project    = "${project}"
  region     = "${region}"
  key_ring   = "${key_ring}"
  crypto_key = "${crypto_key}"
}

# Worker authorization KMS
# Use a production KMS such as AWS KMS for production installs
# This key is the same key used in the worker configuration
kms "gcpckms" {
  purpose    = "worker-auth"
  project    = "${project}"
  region     = "${region}"
  key_ring   = "${key_ring}"
  crypto_key = "${crypto_key}"
}

# Recovery KMS block: configures the recovery key for Boundary
# Use a production KMS such as AWS KMS for production installs
kms "gcpckms" {
  purpose    = "recovery"
  project    = "${project}"
  region     = "${region}"
  key_ring   = "${key_ring}"
  crypto_key = "${crypto_key}"
}