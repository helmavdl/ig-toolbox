#!/bin/bash
set -e

echo "🔍 Checking for updates to key components..."

# --- Check Firely Terminal ---
INSTALLED_FIRELY=$(dotnet tool list -g | grep firely.terminal | awk '{print $2}')
LATEST_FIRELY=$(curl -s https://api.nuget.org/v3-flatcontainer/firely.terminal/index.json | jq -r '.versions[-1]')
echo "Firely Terminal: Installed=$INSTALLED_FIRELY, Latest=$LATEST_FIRELY"
if [ "$INSTALLED_FIRELY" != "$LATEST_FIRELY" ]; then
    read -p "Update Firely Terminal to $LATEST_FIRELY? (y/n): " update_firely
    if [[ "$update_firely" == "y" ]]; then
        dotnet tool update -g firely.terminal
    fi
fi

# --- Check HAPI FHIR CLI ---
HAPI_VERSION="8.2.1"
LATEST_HAPI=$(curl -s https://api.github.com/repos/hapifhir/hapi-fhir/releases/latest | jq -r '.tag_name')
echo "HAPI FHIR CLI: Installed=$HAPI_VERSION, Latest=$LATEST_HAPI"
if [ "v$HAPI_VERSION" != "$LATEST_HAPI" ]; then
    read -p "Update HAPI FHIR CLI to $LATEST_HAPI? (y/n): " update_hapi
    if [[ "$update_hapi" == "y" ]]; then
        curl -SL "https://github.com/hapifhir/hapi-fhir/releases/download/$LATEST_HAPI/hapi-fhir-${LATEST_HAPI#v}-cli.zip" -o /tmp/hapi-cli.zip
        unzip -o /tmp/hapi-cli.zip -d /usr/share/hapi-fhir-cli
        rm /tmp/hapi-cli.zip
        echo "HAPI FHIR CLI updated."
    fi
fi

# --- Check IG Publisher ---
INSTALLED_PUB_VERSION=$(unzip -p /usr/share/igpublisher/publisher.jar META-INF/MANIFEST.MF 2>/dev/null | grep 'Build-Version' | awk '{print $2}')
LATEST_PUB_URL=$(curl -s https://api.github.com/repos/HL7/fhir-ig-publisher/releases/latest | jq -r '.assets[] | select(.name=="publisher.jar") | .browser_download_url')
echo "IG Publisher: Installed=$INSTALLED_PUB_VERSION"
read -p "Update IG Publisher to latest? (y/n): " update_pub
if [[ "$update_pub" == "y" ]]; then
    curl -L "$LATEST_PUB_URL" -o /usr/share/igpublisher/publisher.jar
    echo "IG Publisher updated."
fi

# --- Sushi ---
INSTALLED_SUSHI=$(sushi --version)
LATEST_SUSHI=$(npm show fsh-sushi version)
echo "Sushi: Installed=$INSTALLED_SUSHI, Latest=$LATEST_SUSHI"
if [ "$INSTALLED_SUSHI" != "$LATEST_SUSHI" ]; then
    read -p "Update Sushi to $LATEST_SUSHI? (y/n): " update_sushi
    if [[ "$update_sushi" == "y" ]]; then
        npm install -g fsh-sushi
        echo "Sushi updated."
    fi
fi

echo "Update check complete."
