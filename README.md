# Boundary
## Install controller
### Ubuntu
Add the HashiCorp [GPG key.](https://apt.releases.hashicorp.com/gpg)
```sh
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
```
Add the official HashiCorp Linux repository.
```sh
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
```
Update and install.
```sh
sudo apt-get update && sudo apt-get install boundary
```
Create user & group
```sh 
adduser --system --group boundary
```
Grant permissions on files
```sh
chown -R boundary:boundary /etc/boundary.d
chown boundary:boundary /usr/bin/boundary
```
Create config file by editing `/etc/boundary.d/controller.hcl` use [controller.hcl](controller/controller.hcl) as example.
Init databese
```sh
/usr/bin/boundary database init -config /etc/boundary.d/controller.hcl
```
Fix rights on service file
```sh
chmod 664 /etc/systemd/system/boundary.service
```
Enable and run Boundary controller
```sh
systemctl daemon-reload
systemctl enable boundary
systemctl start boundary
```
## Install worker
### Ubuntu
Add the HashiCorp [GPG key.](https://apt.releases.hashicorp.com/gpg)
```sh
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
```
Add the official HashiCorp Linux repository.
```sh
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
```
Update and install.
```sh
sudo apt-get update && sudo apt-get install boundary
```
Create user & group
```sh 
adduser --system --group boundary
```
Grant permissions on files
```sh
chown -R boundary:boundary /etc/boundary.d
chown boundary:boundary /usr/bin/boundary
```
Create config file by editing `/etc/boundary.d/worker.hcl` use [worker.hcl](worker/worker.hcl) as example.
### Boundary Desktop
[Download](https://developer.hashicorp.com/boundary/tutorials/oss-getting-started/oss-getting-started-desktop-app)   
After installation, auth using login and password **and change** password to your desire
Select target -> Connect -> In terminal you can ssh to `127.0.0.1` and `${PORT}` ex:
```sh
ssh 127.0.0.1 -p 54321 -l username -i /path/to/ssh/key
```
Fix rights on service file
```sh
chmod 664 /etc/systemd/system/boundary.service
```
Enable and run Boundary controller
```sh
systemctl daemon-reload
systemctl enable boundary
systemctl start boundary
```
### Boundary CLI
Get auth-method ID. You will need it to log in
```sh
export BOUNDARY_ADDR=https://boundary.pinesoftware.com.cy:9200
boundary auth-methods list
```
Choose one with Pine name.
And authenticate with your login/password
```sh
boundary authenticate password -auth-method-id ${AUTH_ID} -login-name ${USER_NAME}
```
Now find the scope that you want to use.

```sh
boundary scopes list
```
As always, select the scope ID of the DC.
Now get the scope ID of the "project". In our case, its environment

```sh
boundary scopes list -scope-id ${DC_SCOPE_ID}
```
Select host scope ID
Now list host catalogs and get hosts
```sh
boundary host-catalogs list  -scope-id ${PROJECT_ID}
```
Get target ID
```sh
boundary targets list -scope-id ${PROJECT_ID}
```
Select the host ID and connect to it
```sh
boundary connect ssh -host-id ${HOST_ID} -target-id ${TARGET_ID}$ -- -l user_name -i /path/to/ssh/key
```