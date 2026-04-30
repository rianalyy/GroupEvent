#!/bin/bash
# Usage : ./env.sh run
# Usage : ./env.sh build apk
# Usage : ./env.sh build linux

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

if [ -z "$BREVO_API_KEY" ] || [ -z "$BREVO_SENDER_EMAIL" ]; then
  echo ""
  echo "ERREUR : Variables manquantes dans .env"
  echo ""
  echo "Copiez .env.example en .env et remplissez :"
  echo "  BREVO_API_KEY=votre_cle"
  echo "  BREVO_SENDER_EMAIL=votre@email.com"
  echo ""
  exit 1
fi

flutter "$@" \
  --dart-define="BREVO_API_KEY=$BREVO_API_KEY" \
  --dart-define="BREVO_SENDER_EMAIL=$BREVO_SENDER_EMAIL"
