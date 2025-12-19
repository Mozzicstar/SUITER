#!/bin/bash
# Build and run SUITER components locally

set -e

echo "🚀 Building SUITER System..."

# ============ BUILD MOVE CONTRACTS ============
echo "📦 Building Move contracts..."
cd contracts

if command -v sui &> /dev/null; then
    sui move build
    echo "✓ Move contracts built"
else
    echo "⚠️  sui CLI not installed. Skipping Move build."
    echo "   Install with: curl -fsSL https://sui-releases.s3.amazonaws.com/latest/sui-linux-x86_64 -o sui && chmod +x sui && sudo mv sui /usr/local/bin/"
fi

cd ..

# ============ BUILD RUST INDEXER ============
echo "🔗 Building Rust indexer..."
cd indexer

if command -v cargo &> /dev/null; then
    cargo build --release 2>&1 | tail -20
    echo "✓ Indexer built"
else
    echo "⚠️  Rust/Cargo not installed"
fi

cd ..

# ============ BUILD API SERVER ============
echo "🌐 Building API server..."
cd api

if command -v cargo &> /dev/null; then
    cargo build --release 2>&1 | tail -20
    echo "✓ API server built"
else
    echo "⚠️  Rust/Cargo not installed"
fi

cd ..

echo ""
echo "✅ Build complete!"
echo ""
echo "Next steps:"
echo "1. Setup database: sudo -u postgres createdb suiter && psql suiter < database/migrations/001_init.sql"
echo "2. Start indexer: ./indexer/target/release/suiter-indexer"
echo "3. Start API: ./api/target/release/suiter-api"
echo "4. Deploy contracts: sui client publish --gas-budget 200000000 ./contracts"
