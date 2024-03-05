FROM debian:bookworm-slim

# Install OS dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends locales git openjdk-17-jre ruby-full build-essential zlib1g-dev nodejs npm curl unzip plantuml graphviz jq\
    && rm -rf /var/lib/apt/lists/*

# Fix locale issues in various environments
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

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