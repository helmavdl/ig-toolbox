FROM debian:bookworm-slim

# Install OS dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends git openjdk-17-jre ruby-full build-essential zlib1g-dev nodejs npm curl unzip\
    && rm -rf /var/lib/apt/lists/*

# Install Jekyll
RUN gem install -N jekyll bundler

# Install FHIR Sushi, GoFSH and BonFHIR CLI
RUN npm i -g fsh-sushi gofsh @bonfhir/cli

# Install Firely Terminal
RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin -Channel 6.0 -InstallDir /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet
RUN dotnet tool install -g firely.terminal

# Install HAPI FHIR CLI
RUN mkdir -p /share/src/hapi-fhir-cli \
    && curl -SL https://github.com/hapifhir/hapi-fhir/releases/download/v7.0.0/hapi-fhir-7.0.0-cli.zip -o /usr/share/hapi-fhir-cli.zip \
    && unzip -q /usr/share/hapi-fhir-cli.zip -d /usr/share/hapi-fhir-cli \
    && rm -f /usr/share/hapi-fhir-cli.zip

# Update the path
RUN <<EOF cat >> ~/.bashrc
export PATH="\$PATH:/root/.dotnet/tools:/usr/share/hapi-fhir-cli"
EOF

# Default working directory
RUN mkdir /workspaces
WORKDIR /workspaces

CMD [ "/bin/bash" ]