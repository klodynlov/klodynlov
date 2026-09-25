#!/usr/bin/env bash
# Génère (ou régénère) KaribTruck.xcodeproj depuis project.yml.
# Usage : ./generate.sh   (depuis karibtruck/App)
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen n'est pas installé."
  if command -v brew >/dev/null 2>&1; then
    echo "Installation via Homebrew…"
    brew install xcodegen
  else
    echo "Installez Homebrew (https://brew.sh) puis : brew install xcodegen"
    echo "Alternative : mint install yonaskolb/xcodegen"
    exit 1
  fi
fi

xcodegen generate
echo "✓ KaribTruck.xcodeproj généré."
echo "  Ouvrez-le :  open KaribTruck.xcodeproj"
echo "  Puis, dans Signing & Capabilities, choisissez votre équipe développeur."
