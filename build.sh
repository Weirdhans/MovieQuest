#!/bin/bash
set -e

# Create .env file from Vercel environment variables
printf 'SUPABASE_URL=%s\nSUPABASE_ANON_KEY=%s\nTMDB_API_KEY=%s\nTMDB_BASE_URL=%s\nTMDB_IMAGE_BASE=%s\n' \
  "$SUPABASE_URL" \
  "$SUPABASE_ANON_KEY" \
  "$TMDB_API_KEY" \
  "$TMDB_BASE_URL" \
  "$TMDB_IMAGE_BASE" > .env

# Build Flutter web with CanvasKit renderer
flutter/bin/flutter build web --release --web-renderer canvaskit
