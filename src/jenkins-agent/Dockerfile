FROM jenkins/inbound-agent

# whoami == jenkins.  Come back to that
USER root
RUN apt update && apt upgrade -y

# Install helm
RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash && helm version --client


# Get kubectl
ARG KUBECTL_VERSION=v1.28.3
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# Get AWS CLI
RUN apt install unzip \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws \
    && apt remove unzip -y

USER jenkins