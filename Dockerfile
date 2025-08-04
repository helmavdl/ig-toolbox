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
RUN curl -sSL https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -o packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update && apt-get install -y dotnet-sdk-8.0 \
    && rm -rf /var/lib/apt/lists/*

# Set up Firely Terminal 3.4.0
ENV DOTNET_ROOT="/usr/share/dotnet" 
ENV PATH="$PATH:/root/.dotnet/tools:/usr/share/hapi-fhir-cli"
RUN dotnet tool install -g firely.terminal --version 3.4.0


# Install our little helper scripts
COPY add-vscode-files /usr/bin/add-vscode-files
COPY add-profile /usr/bin/add-profile
COPY add-fhir-resource-diagram /usr/bin/add-fhir-resource-diagram

# Install Oh-my-bash
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Update the PATH
RUN <<EOF cat >> ~/.bashrc
export PATH="\$PATH:/root/.dotnet/tools:/usr/share/hapi-fhir-cli"
EOF

# Default working directory
RUN mkdir /workspaces
WORKDIR /workspaces

CMD [ "/bin/bash" ]