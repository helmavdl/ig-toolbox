FROM debian:bookworm-slim

# Install OS dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    locales git \
    openjdk-17-jre ruby-full \
    build-essential zlib1g-dev \
    nodejs npm \
    curl unzip \
    plantuml graphviz \
    nginx gettext-base \
    jq \
    gnupg ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Fix locale issues
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG="en_US.UTF-8" 
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"

# Install Jekyll
RUN gem install -N jekyll bundler

# Install FHIR Sushi, GoFSH and BonFHIR CLI
RUN npm install -g fsh-sushi gofsh @bonfhir/cli

# Install .NET 8 SDK for Firely Terminal 3.4.0
# Install .NET 8.0 SDK using the official install script
RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh \
    && bash dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && rm dotnet-install.sh

# Set up Firely Terminal 3.4.0
ENV DOTNET_ROOT="/usr/share/dotnet" 
ENV PATH="$PATH:/root/.dotnet/tools:/usr/share/hapi-fhir-cli"
RUN dotnet tool install -g firely.terminal --version 3.4.0

# Install HAPI FHIR CLI 8.2.1
RUN mkdir -p /usr/share/hapi-fhir-cli \
    && curl -SL https://github.com/hapifhir/hapi-fhir/releases/download/v8.2.1/hapi-fhir-8.2.1-cli.zip -o /tmp/hapi-cli.zip \
    && unzip -q /tmp/hapi-cli.zip -d /usr/share/hapi-fhir-cli \
    && rm -f /tmp/hapi-cli.zip

# Install FHIR IG Publisher
RUN mkdir -p /usr/share/igpublisher \
    && curl -L https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar -o /usr/share/igpublisher/publisher.jar

# Add helper scripts
COPY add-vscode-files /usr/bin/add-vscode-files
COPY add-profile /usr/bin/add-profile
COPY add-fhir-resource-diagram /usr/bin/add-fhir-resource-diagram

# Make a shortcut command
RUN echo '#!/bin/bash\njava -jar /usr/share/igpublisher/publisher.jar "$@"' > /usr/bin/publisher \
    && chmod +x /usr/bin/publisher

# Install Oh-my-bash
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Copy nginx config and start script
COPY run_nginx.sh /run_nginx.sh
RUN chmod +x /run_nginx.sh

EXPOSE 80

# copy the update checker
COPY update-checker.sh /usr/bin/update-checker.sh
RUN chmod +x /usr/bin/update-checker.sh

# Set working directory
RUN mkdir /workspaces
WORKDIR /workspaces

# Entry script that runs nginx + update checker + shell
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
