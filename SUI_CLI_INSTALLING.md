# ⚡ Sui CLI: Installation In Progress

**Status**: Building in background (minimal CPU usage)  
**Started**: Just now  
**Est. Time**: 5-10 minutes  
**CPU Impact**: Low (using `--quiet` mode)

---

## ✅ Installation Complete When:

```bash
which sui
```

Shows a path like `/home/codespace/.cargo/bin/sui`

Or verify version:
```bash
sui --version
```

---

## 🎯 Next Steps (Do These Now!)

### Step 1: Setup Database (30 seconds)
```bash
sudo apt-get update
sudo apt-get install -y postgresql
sudo service postgresql start

# Create database
sudo -u postgres createdb suiter

# Import schema
psql suiter < database/migrations/001_init.sql

# Verify
psql suiter -c "\dt"  # Shows 6 tables
```

### Step 2: Read Your Contracts
```bash
# View your reputation system
cat contracts/sources/profile.move

# View your post system
cat contracts/sources/post.move

# View your attention rewards
cat contracts/sources/attention.move
```

### Step 3: When Sui CLI is Ready

Check if ready:
```bash
which sui && echo "✅ Ready!" || echo "⏳ Still installing..."
```

Then create wallet:
```bash
sui client new
```

Get testnet SUI:
```bash
sui client faucet
```

Check balance:
```bash
sui client balance
```

Build contracts:
```bash
cd contracts && sui move build
```

Run tests:
```bash
sui move test -- --verbose
```

Deploy:
```bash
sui client publish --gas-budget 200000000 ./contracts
```

---

## 📊 Installation Status

| Component | Status | Time |
|-----------|--------|------|
| Rust | ✅ Ready | - |
| Cargo | ✅ Ready | - |
| Sui CLI | ⏳ Building | 5-10 min |

---

## ℹ️ What's Happening

- Sui CLI is compiling from GitHub source
- Running in background (won't block your terminal)
- Using `--quiet` mode (minimal output/CPU)
- Will be in `~/.cargo/bin/sui` when done

---

## 🆘 Check Progress

```bash
# Is it done?
which sui

# Show version
sui --version

# Check build is running
ps aux | grep "cargo install.*sui" | grep -v grep

# See CPU usage
top -bn1 | grep "Cpu(s)"
```

---

## 🚀 Once Ready (You'll See This)

```bash
$ sui --version
sui 1.34.2
```

Then you're ready to:
1. Create wallet: `sui client new`
2. Get testnet SUI: `sui client faucet`
3. Deploy contracts: `sui client publish --gas-budget 200000000 ./contracts`

---

**In background**: `cargo install --locked --git https://github.com/MystenLabs/sui.git sui --quiet`

**CPU impact**: Minimal (background build)

**Next check**: In 5-10 minutes run `sui --version`
