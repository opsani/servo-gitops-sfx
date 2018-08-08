FROM python:3.6-slim

WORKDIR /servo

# Install dependencies
RUN pip3 install -U pip setuptools wheel && \
    pip3 install signalfx requests PyYAML 'ruamel.yaml<0.15'
RUN apt-get update && \
    apt-get install -y --no-install-recommends git openssh-client

# Install optional packages used for testing - not required for servo operation
RUN apt-get install -y --no-install-recommends apache2-utils
ADD https://storage.googleapis.com/kubernetes-release/release/v1.10.0/bin/linux/amd64/kubectl \
    /usr/local/bin/kubectl

# Install servo
ADD https://raw.githubusercontent.com/opsani/servo-gitops/master/adjust \
    https://raw.githubusercontent.com/opsani/servo-gitops/master/formula.py \
    https://raw.githubusercontent.com/opsani/servo-sfx/master/measure \
    https://raw.githubusercontent.com/opsani/servo/master/adjust.py \
    https://raw.githubusercontent.com/opsani/servo/master/measure.py \
    https://raw.githubusercontent.com/opsani/servo/master/servo \
    /servo/
RUN chmod a+rwx /servo/adjust /servo/measure /servo/servo /usr/local/bin/kubectl
RUN chmod a+rw /servo/measure.py

# Setup for non-interactive git operations using ssh:  mkdir for root id_rsa
# private key (mount); create ssh wrapper for env var GIT_SSH; configure git
RUN mkdir /root/.ssh && \
    chmod 700 /root/.ssh && \
    echo 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $*' > /servo/ssh && \
    chmod 755 /servo/ssh && \
    git config --global user.name "Optune Servo" && \
    git config --global user.email "servo@optune.ai" && \
    git config --global push.default simple
ENV GIT_SSH=/servo/ssh

ENV PYTHONUNBUFFERED=1

ENTRYPOINT [ "python3", "servo" ]
