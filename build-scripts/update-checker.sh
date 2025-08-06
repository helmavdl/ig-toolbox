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
INSTALLED_PUB_VERSION=$(java -jar /usr/share/igpublisher/publisher.jar --version 2>/dev/null | \
    grep -oE 'FHIR IG Publisher Version [0-9]+\.[0-9]+\.[0-9]+' | \
    sed 's/FHIR IG Publisher Version //')
LATEST_PUB_VERSION=$(curl -s https://api.github.com/repos/HL7/fhir-ig-publisher/releases/latest | jq -r '.name')
echo "IG Publisher: Installed=$INSTALLED_PUB_VERSION, Latest=$LATEST_PUB_VERSION"

if [ "$INSTALLED_PUB_VERSION" != "$LATEST_PUB_VERSION" ]; then
    read -p "Update IG Publisher to latest? (y/n): " update_pub
    if [[ "$update_pub" == "y" ]]; then
        LATEST_PUB_URL=$(curl -s https://api.github.com/repos/HL7/fhir-ig-publisher/releases/latest | jq -r '.assets[] | select(.name=="publisher.jar") | .browser_download_url')
        curl -L "$LATEST_PUB_URL" -o /usr/share/igpublisher/publisher.jar
        echo "IG Publisher updated."
    fi
fi

# --- Check HL7 FHIR Validator ---
INSTALLED_VALIDATOR_VERSION=$(java -jar /usr/share/validator_cli.jar --help 2>&1 | grep -oE 'FHIR Validation tool Version [0-9]+\.[0-9]+\.[0-9]+' | sed 's/FHIR Validation tool Version //')
LATEST_VALIDATOR_VERSION=$(curl -s https://api.github.com/repos/hapifhir/org.hl7.fhir.core/releases/latest | jq -r '.tag_name')
echo "FHIR Validator: Installed=$INSTALLED_VALIDATOR_VERSION, Latest=$LATEST_VALIDATOR_VERSION"

if [ "$INSTALLED_VALIDATOR_VERSION" != "$LATEST_VALIDATOR_VERSION" ]; then
  read -p "Update FHIR Validator to latest? (y/n): " update_val
  if [[ "$update_val" == "y" ]]; then
    LATEST_VALIDATOR_URL="https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar"
    curl -L "$LATEST_VALIDATOR_URL" -o /usr/share/validator_cli.jar
    echo "FHIR Validator updated."
  fi
fi

# --- Sushi ---
INSTALLED_SUSHI=$(sushi --version | grep -oE 'SUSHI v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/SUSHI v//')
LATEST_SUSHI=$(npm show fsh-sushi version)
echo "Sushi: Installed=$INSTALLED_SUSHI, Latest=$LATEST_SUSHI"
if [ "$INSTALLED_SUSHI" != "$LATEST_SUSHI" ]; then
    read -p "Update Sushi to $LATEST_SUSHI? (y/n): " update_sushi
    if [[ "$update_sushi" == "y" ]]; then
        npm install -g fsh-sushi
        echo "Sushi updated."
    fi
fi

# --- Check BonFHIR CLI ---
INSTALLED_BONFHIR_VERSION=$(bonfhir --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
LATEST_BONFHIR_VERSION=$(npm view @bonfhir/cli version 2>/dev/null)

echo "BonFHIR CLI: Installed=$INSTALLED_BONFHIR_VERSION, Latest=$LATEST_BONFHIR_VERSION"

if [ "$INSTALLED_BONFHIR_VERSION" != "$LATEST_BONFHIR_VERSION" ]; then
  read -p "Update BonFHIR CLI to latest? (y/n): " update_bonfhir
  if [[ "$update_bonfhir" == "y" ]]; then
    npm install -g @bonfhir/cli
    echo "✅ BonFHIR CLI updated."
  fi
fi


echo "Update check complete."
