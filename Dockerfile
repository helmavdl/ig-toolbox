FROM debian:bookworm-slim

# Install OS dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends git openjdk-17-jre ruby-full build-essential zlib1g-dev nodejs npm curl\
    && rm -rf /var/lib/apt/lists/*

# Install Jekyll
RUN gem install -N jekyll bundler

# Install FHIR Sushi, GoFSH and BonFHIR CLI
RUN npm i -g fsh-sushi gofsh @bonfhir/cli

# Install Firely Terminal
RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin -Channel 6.0 -InstallDir /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet
RUN dotnet tool install -g firely.terminal
RUN <<EOF cat >> ~/.bashrc
# Add .NET Core SDK tools
export PATH="\$PATH:/root/.dotnet/tools"
EOF

# Usability
RUN mkdir /workspaces
WORKDIR /workspaces

CMD [ "/bin/bash" ]