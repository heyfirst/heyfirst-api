#!/bin/sh
set -e

# Run migration
echo "Run migration..."
npx prisma migrate deploy

# Start app
echo "Starting app..."
node ./dist/index.js
