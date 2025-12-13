# Splunk MCP Setup Guide

**Enable Splunk context in Claude Code for TA-suhlabs-eMASS development**

---

## Available Splunk MCP Servers

### 1. **Splunk Official** (Recommended)
- **Repo:** https://github.com/splunk/splunk-mcp-server2
- **Language:** Python + TypeScript
- **Features:**
  - Run SPL searches
  - Query Splunk
  - Output as JSON/CSV/Markdown
  - Input SPL validation
  - Output sanitization
  - SSE/stdio transport

### 2. **Livehybrid**
- **Repo:** https://github.com/livehybrid/splunk-mcp
- **Language:** Python
- **Features:**
  - Splunk Enterprise/Cloud integration
  - Cursor IDE/Claude integration
  - Production tested

### 3. **Deslicer** (Most Features)
- **Repo:** https://github.com/deslicer/mcp-for-splunk
- **Language:** Node.js
- **Features:**
  - 20+ tools
  - 16 resources (CIM data models)
  - Production-ready security
  - Comprehensive Splunk integration

---

## Installation Options

### Option 1: Official Splunk MCP (Python)

```bash
# Install from GitHub
cd /home/suhlabs
git clone https://github.com/splunk/splunk-mcp-server2.git
cd splunk-mcp-server2

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export SPLUNK_HOST=localhost:8089
export SPLUNK_TOKEN=your-splunk-token
```

### Option 2: NPM Package (Node.js)

```bash
# Install globally
npm install -g mcp-for-splunk

# Or use npx (no install needed)
npx -y mcp-for-splunk
```

### Option 3: Docker

```bash
# Pull and run Splunk MCP server
docker run -d \
  -e SPLUNK_HOST=localhost:8089 \
  -e SPLUNK_TOKEN=your-token \
  -p 3000:3000 \
  splunk/mcp-server:latest
```

---

## Configuration

### 1. Get Splunk API Token

```bash
# SSH into Splunk instance or use local Splunk
curl -k -u admin:Password123! \
  https://localhost:8089/services/authorization/tokens?output_mode=json \
  -d name=mcp-token -d audience=mcp

# Save the token
export SPLUNK_TOKEN=<your-token>
```

### 2. Enable MCP Server in Claude Code

Edit: `/home/suhlabs/.config/Code/User/mcp.json`

**Choose ONE server and enable it:**

```json
{
  "mcpServers": {
    "splunk-official": {
      "disabled": false,  // ← Change to false
      // ... rest of config
    }
  }
}
```

### 3. Restart Claude Code

```bash
# Restart VSCode/Claude Code to load MCP
```

---

## Testing MCP Connection

Once configured, you can test in Claude Code:

```
Ask Claude: "List available Splunk indexes"
Ask Claude: "Run SPL query: index=_internal | head 10"
Ask Claude: "Show Splunk data models"
```

---

## Use Cases for TA-suhlabs-eMASS

### 1. Query eMASS POA&M Data

```
"Search for POA&Ms with status 'Ongoing' in the last 30 days"
```

### 2. Validate SPL Queries

```
"Validate this SPL query: index=mnhrs_emass_poc sourcetype=emass:poam | stats count by status"
```

### 3. Generate Dashboards

```
"Create a dashboard panel for POA&M severity distribution"
```

### 4. Data Model Exploration

```
"What fields are available in the emass:poam sourcetype?"
```

### 5. Development Assistance

```
"Generate inputs.conf for collecting POA&M data every hour"
```

---

## Environment Variables Reference

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SPLUNK_HOST` | Splunk instance hostname:port | `localhost:8089` |
| `SPLUNK_TOKEN` | API token | `eyJraWQiOiJ...` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `SPLUNK_USERNAME` | Admin username | `admin` |
| `SPLUNK_PASSWORD` | Admin password | - |
| `SPLUNK_SCHEME` | HTTP scheme | `https` |
| `SPLUNK_VERIFY_SSL` | Verify SSL certs | `false` |
| `SPLUNK_PORT` | Management port | `8089` |

---

## Troubleshooting

### Connection Failed

```bash
# Test Splunk connectivity
curl -k https://localhost:8089/services/server/info

# Check token
echo $SPLUNK_TOKEN
```

### MCP Not Loading

```bash
# Check MCP config syntax
jq empty ~/.config/Code/User/mcp.json

# View Claude Code logs
tail -f ~/.config/Code/logs/main.log
```

### Permission Denied

```bash
# Ensure Splunk token has correct permissions
# Token needs: search, edit, list capabilities
```

---

## Security Best Practices

### 1. Use Environment Variables

Don't hardcode credentials in mcp.json:

```json
{
  "env": {
    "SPLUNK_TOKEN": "${SPLUNK_TOKEN}"  // ✅ Uses env var
  }
}
```

### 2. Restrict Token Permissions

Create limited-scope token:

```bash
# Create token with only search permissions
curl -k -u admin:pass https://localhost:8089/services/authorization/tokens \
  -d name=mcp-readonly \
  -d capabilities="search"
```

### 3. Use SSL Verification in Production

```json
{
  "env": {
    "SPLUNK_VERIFY_SSL": "true"
  }
}
```

---

## Advanced: Custom MCP Server

If you need custom Splunk integration for eMASS:

```bash
# Create custom MCP server
cd /home/suhlabs/projects/suhlabs
mkdir splunk-emass-mcp
cd splunk-emass-mcp

# Initialize
npm init -y
npm install @modelcontextprotocol/sdk

# Implement custom tools for eMASS POA&M queries
# See: https://github.com/modelcontextprotocol/servers
```

---

## Resources

- **Official MCP Docs:** https://modelcontextprotocol.io
- **Splunk MCP Server:** https://github.com/splunk/splunk-mcp-server2
- **MCP Servers Collection:** https://github.com/modelcontextprotocol/servers
- **Splunk Community:** https://community.splunk.com/t5/Splunk-Enterprise/Splunk-MCP-Server/m-p/750634

---

**Status:** Configuration created, ready to enable
**Next Step:** Install chosen MCP server and enable in mcp.json
**Date:** 2025-11-01
