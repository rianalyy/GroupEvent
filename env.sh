#!/bin/bash

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

if [ -z "$RESEND_API_KEY" ]; then
  echo ""
  echo "ERREUR : RESEND_API_KEY non défini."
  echo "1. Copiez .env.example en .env"
  echo "2. Ajoutez votre clé Resend dans .env"
  echo ""
  exit 1
fi

flutter "$@" --dart-define="RESEND_API_KEY=$RESEND_API_KEY"
