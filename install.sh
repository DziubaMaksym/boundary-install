#!/bin/bash
# Installs the boundary as a service for systemd on linux
# Usage: ./install.sh <worker|controller>
set -e

TYPE=$1
NAME=boundary

if [ ${TYPE} = "controller" ]; then
  echo "Boundary controller setup"
else
  echo "Boundary worker setup"
fi
apt-get -qq --yes update
apt-get -qq --yes upgrade
apt-get install -qq --yes curl htop software-properties-common

echo "Additional packages installed!"
echo ""

curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get -qq --yes update
apt-get install -qq --yes boundary

echo "Boundary installed!"
echo ""

cat >/etc/systemd/system/${NAME}.service <<EOF
[Unit]
Description=${NAME} ${TYPE}

[Service]
ExecStart=/usr/bin/${NAME} server -config /etc/boundary.d/${TYPE}.hcl
User=boundary
Group=boundary
LimitMEMLOCK=infinity
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK

[Install]
WantedBy=multi-user.target
EOF

echo "Boundary service file created!"
echo ""

# Add the boundary system user and group to ensure we have a no-login
# user capable of owning and running Boundary

adduser --system --group boundary
chown -R boundary:boundary /etc/boundary.d
chown boundary:boundary /usr/bin/boundary

echo "Boundary user & group added!"
echo ""
# Make sure to initialize the DB before starting the service. This will result in
# a database already initialized warning if another controller or worker has done this
# already, making it a lazy, best effort initialization

if [ ${TYPE} = "controller" ]; then
  cat >/etc/boundary.d/controller.hcl <<'EOF'
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
EOF
  /usr/bin/boundary database init -config /etc/boundary.d/controller.hcl || true
else
  cat >/etc/boundary.d/worker.hcl <<'EOF'
listener "tcp" {
  purpose     = "proxy"
  tls_disable = true
}

worker {
  # Name attr must be unique
  name        = "worker-${count.index}"
  description = "A default worker created"
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

EOF
fi

chmod 664 /etc/systemd/system/${NAME}.service
systemctl daemon-reload
systemctl enable ${NAME}
systemctl start ${NAME}

exit 0
