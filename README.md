# Optune Servo with GitOps (adjust) and SignalFx (measure) drivers

## Build and push servo container
```
docker build . -t example.com/servo-gitops-sfx:latest
docker push example.com/servo-gitops-sfx:latest
```

## Running servo as a Docker container

See the [servo-sfx](https://github.com/opsani/servo-sfx) and [servo-gitops](https://github.com/opsani/servo-gitops) repository READMEs for detailed instructions on configuring the servo.

The bash script below is provided as a template for configuring and running the servo as a docker container.

```
#!/bin/bash

# Config
DOCKER_IMG=opsani/servo-gitops-sfx:latest
OPTUNE_AUTH_TOKEN=<change_me>
OPTUNE_ACCOUNT=<change_me>
OPTUNE_APP_ID=<change_me>
SFX_API_TOKEN=<change_me>

# Pull servo image
docker pull $DOCKER_IMG

# Create Optune auth token file under /opt/optune
mkdir -p /opt/optune
echo $OPTUNE_AUTH_TOKEN > /opt/optune/auth_token
chmod 600 /opt/optune/auth_token

# Create SignalFx API token file under /opt/optune
echo $SFX_API_TOKEN > /opt/optune/sfx_api_token
chmod 600 /opt/optune/sfx_api_token

# Create ssh private key file (git repository deploy key)
cat << EOF > /opt/optune/ssh-key
-----BEGIN RSA PRIVATE KEY-----
MIIJKgIBAAKCAgEAx1XEYymwB5xZuIz2OvBF2On0obHRFeaWKDzso3Fbkh4eu4fK
O5vs60Ae0M7Kjlj3cTcR9u5DxwUAmr5LUSafcDsDE2AF9ayOREzWUpqvwZTt5Pyf
DFrWgjBDS08mSdprRgItJZr6k8hoaAgEcqiVPkT/ChtBeEdgjCBhJk4XAKxfFngX

... <change_me> ...

3FtMBdE/iRyo7oCMKAsKnKWYPbr+QAH/Hr05ITXRujIyObYYaTaXLfW5eohIY6FD
r4/kulszslag9+jHYRf/sy9uGappMo8usXHlu4bTHvmG+W6DPlRAWlQM9SGl14OR
ZA6vyIaoBnGE5va8L2hXES15QpbIvBug/mielhQQy5jCSiio38XTzTyZ76UOqg==
-----END RSA PRIVATE KEY-----
EOF
chmod 600 /opt/optune/ssh-key

# Create servo config file
cat << 'EOF' > /opt/optune/config.yaml

sfx:
    #pre_cmd:       <user command, e.g. start load generation>
    #post_cmd:      <user command, e.g. stop load generation>
    metrics:
        perf:
            flow_program:  "data('pod_network_transmit_bytes_total',filter('kubernetes_namespace','abc')).publish()"
            time_aggr:     avg
            space_aggr:    sum
            unit:          bytes

gitops:
    git_url:     ssh://git@github.com/<my_user>/<my_repo>.git
    git_branch:  <my_branch>
    #pre_cmd:    <user command>
    #post_cmd:   <user command, e.g. verify git repo changes are deployed>
    components:
        c1:
            git_file:  test.yml
            settings:
                cpu:
                    key_path:    ['main_uswest1', 'cpus']
                    min:         1
                    max:         16
                    type:        range
                    value_conv:  int
                apache_workers:
                    key_path:    ['main_uswest1', 'env', 'APACHE_WORKERS']
                    min:         1
                    max:         20
                    type:        range
                    value_conv:  str_int
            dependencies:
                mem:
                    key_path: ['main_uswest1', 'mem']
                    formula:  '(int(apache_workers) * 1000) + 500'

EOF

# Start servo container
docker rm -f servo-gitops-sfx || true
docker run -d --restart=always \
    --name servo-gitops-sfx \
    -v /opt/optune/auth_token:/opt/optune/auth_token \
    -v /opt/optune/config.yaml:/servo/config.yaml \
    -v /opt/optune/ssh-key:/root/.ssh/id_rsa \
    -v /opt/optune/sfx_api_token:/etc/optune-sfx-auth/api_key \
    $DOCKER_IMG --auth-token /opt/optune/auth_token \
    --account $OPTUNE_ACCOUNT --verbose \
    $OPTUNE_APP_ID
```

