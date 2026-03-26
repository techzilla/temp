#!/bin/sh
set -eu

if [ $# -lt 1 ]; then
  echo "Usage: $0 publisher.extension [version|latest]" >&2
  exit 1
fi

EXT_FULL="$1"
REQ_VERSION="${2:-latest}"

PUBLISHER=$(printf "%s" "$EXT_FULL" | cut -d. -f1)
EXT_NAME=$(printf "%s" "$EXT_FULL" | cut -d. -f2-)

API_URL="https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"

# Build request JSON (no bashisms)
if 

[ "$REQ_VERSION" = "latest" ]; then
  JSON=$(cat <<EOF
{
  "filters": [{
    "criteria": [
      {"filterType": 7, "value": "$EXT_FULL"}
    ]
  }],
  "flags": 103
}
EOF
)
else
  JSON=$(cat <<EOF
{
  "filters": [{
    "criteria": [
      {"filterType": 7, "value": "$EXT_FULL"},
      {"filterType": 8, "value": "$REQ_VERSION"}
    ]
  }],
  "flags": 103
}
EOF
)
fi

# Query API
RESP=$(curl -fsSL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json;api-version=3.0-preview.1" \
  -d "$JSON" \
  "$API_URL")

# Extract version (requires jq)
REAL_VERSION=$(printf "%s" "$RESP" | jq -r '.results[0].extensions[0].versions[0].version')

if [ -z "$REAL_VERSION" ] || [ "$REAL_VERSION" = "null" ]; then
  echo "Failed to resolve version for $EXT_FULL" >&2
  exit 1
fi

VSIX_URL="https://${PUBLISHER}.gallery.vsassets.io/_apis/public/gallery/publisher/${PUBLISHER}/extension/${EXT_NAME}/${REAL_VERSION}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"

OUT="${PUBLISHER}.${EXT_NAME}-${REAL_VERSION}.vsix"

curl -sfL -o "$OUT" "$VSIX_URL"

