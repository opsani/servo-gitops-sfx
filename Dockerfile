FROM python:3.6-slim

WORKDIR /servo

# Install dependencies:  apache2-utils is used for testing - not required for
# servo operation
RUN pip3 install -U pip setuptools wheel && \
    pip3 install signalfx ruamel.yaml requests PyYAML
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apache2-utils git openssh-client && \
    apt-get clean

# Install kubectl:  used for testing - not required for servo operation
ADD https://storage.googleapis.com/kubernetes-release/release/v1.10.0/bin/linux/amd64/kubectl /usr/local/bin/kubectl

# Install servo
ADD https://raw.githubusercontent.com/opsani/servo-gitops/master/adjust \
    https://raw.githubusercontent.com/opsani/servo-sfx/master/measure \
    https://raw.githubusercontent.com/opsani/servo/master/adjust.py \
    https://raw.githubusercontent.com/opsani/servo/master/measure.py \
    https://raw.githubusercontent.com/opsani/servo/master/servo \
    /servo/
RUN chmod a+rwx /servo/adjust /servo/measure /servo/servo /usr/local/bin/kubectl
RUN chmod a+rw /servo/measure.py

# Setup ssh for use with git operations:  mkdir for id_rsa private key (mount);
# create ssh wrapper for env var GIT_SSH; and setup git user
RUN mkdir /root/.ssh
RUN chmod 700 /root/.ssh
RUN echo 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $*' > /servo/ssh
RUN chmod 755 /servo/ssh
ENV GIT_SSH=/servo/ssh
RUN git config --global user.name "Optune Servo"
RUN git config --global user.email "servo@optune.ai"
RUN git config --global push.default simple

ENV PYTHONUNBUFFERED=1

ENTRYPOINT [ "python3", "servo" ]
