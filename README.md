# TA-suhlabs-eMASS

## Splunk Technology Add-on for eMASS (Enterprise Mission Assurance Support Service)

Ingest Plan of Action and Milestones (POA&M) data from eMASS into Splunk for security compliance monitoring and reporting.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Splunk](https://img.shields.io/badge/Splunk-9.2.1+-green.svg)](https://www.splunk.com)
[![UCC](https://img.shields.io/badge/UCC-6.0.1-orange.svg)](https://github.com/splunk/addonfactory-ucc-generator)

---

## Features

- ✅ **Multi-Account Support** - Configure multiple eMASS instances
- ✅ **Automated POA&M Collection** - Scheduled data ingestion with checkpointing
- ✅ **Secure Credential Storage** - Encrypted API keys in Splunk storage/passwords
- ✅ **Flexible Indexing** - Route data to any Splunk index
- ✅ **UCC Framework** - Modern Splunk add-on architecture

---

## Prerequisites

- **Splunk Enterprise** 9.0+ or **Splunk Cloud**
- **Python** 3.12+ (for development/building)
- **eMASS API Access** - Valid API key and System ID
- **Make** - For build automation (optional but recommended)

---

## Architecture

Built with [Splunk UCC Framework](https://splunk.github.io/addonfactory-ucc-generator/):

- **Account-based Configuration** - Reusable credentials across inputs
- **REST API Integration** - Connects to eMASS POA&M endpoints
- **Modular Input Design** - Configurable collection intervals
- **Checkpointing** - Prevents duplicate data ingestion

---

## Quick Start

### 1. Setup Development Environment

```bash
make preflight  # Verify prerequisites
make setup      # Create venv and install dependencies
```

### 2. Build the Add-on

```bash
make build      # Build with UCC
make validate   # Verify outputs
```

### 3. Deploy to Splunk

```bash
# Copy to Splunk apps directory
cp -r output/TA-suhlabs-eMASS $SPLUNK_HOME/etc/apps/

# Restart Splunk
$SPLUNK_HOME/bin/splunk restart
```

### 4. Configure in Splunk Web

1. Navigate to **Apps → TA-suhlabs-eMASS → Configuration**
2. **Add Account**:
   - Account Name: `emass_prod`
   - System ID: `55090` (your eMASS system ID)
   - Base URL: `https://emass.mil` (or your eMASS instance)
   - API Key: `<your-api-key>`
   - Default Index: `emass` (or preferred index)
3. **Add Input**:
   - Input Name: `emass_poam_collection`
   - Account: Select `emass_prod`
   - Interval: `3600` (seconds, e.g., 1 hour)
   - Index: Auto-filled from account or override

---

## Configuration

### eMASS Account Settings

| Field         | Required | Description                                         |
| ------------- | -------- | --------------------------------------------------- |
| Account Name  | Yes      | Unique identifier (alphanumeric + underscore)       |
| System ID     | Yes      | eMASS System ID (numeric)                           |
| Base URL      | Yes      | eMASS API base URL                                  |
| API Key       | Yes      | eMASS API authentication key (encrypted)            |
| User UID      | No       | Optional user identifier for some eMASS deployments |
| Default Index | Yes      | Splunk index for POA&M data                         |

### Data Input Settings

| Field      | Required | Description                                             |
| ---------- | -------- | ------------------------------------------------------- |
| Input Name | Yes      | Unique input identifier                                 |
| Account    | Yes      | Reference to configured eMASS account                   |
| Interval   | Yes      | Collection frequency in seconds (min: 1, max: 31536000) |
| Index      | Yes      | Override account default index if needed                |

---

## Development

### Build from Source

```bash
# Full build pipeline
make preflight && make build && make validate
```

### Local Testing with Docker

```bash
make image              # Build Splunk container with add-on
docker-compose up -d    # Start Splunk instance
```

**Access Local Splunk:**

- URL: http://localhost:8000
- User: `admin`
- Pass: `Password123!`

### Project Structure

```text
TA-suhlabs-eMASS/
├── package/                    # Source files for UCC
│   ├── bin/                   # Python scripts and REST handlers
│   ├── default/               # Default configurations
│   ├── appserver/             # Web UI assets
│   └── globalConfig.json      # UCC configuration
├── output/                    # Built add-on (git-ignored)
├── Makefile                   # Build automation
├── requirements.txt           # Python dependencies
└── README.md                  # This file
```

---

## Data Collection

### POA&M Fields Collected

- POA&M ID, External UID
- Control Acronym, AP Acronym
- Status, Scheduled Completion Date
- Comments, Resources, Milestones
- Weakness Detection Source
- Raw JSON response for complete data

### Sourcetype

```text
sourcetype="emass:poam"
```

### Sample Search

```spl
index=emass sourcetype="emass:poam"
| stats count by status, controlAcronym
```

---

## Troubleshooting

| Issue                    | Solution                                                           |
| ------------------------ | ------------------------------------------------------------------ |
| **Permission errors**    | Run `chmod +x` on scripts or `chown` as needed                     |
| **Build recursion**      | Verify `.uccignore` includes `output/`                             |
| **UI not loading**       | Check `appserver/static/js/build/` has 22+ JS files                |
| **API connection fails** | Verify Base URL and API Key in account settings                    |
| **No data ingested**     | Check `index=_internal sourcetype=ta:suhlabs:emass:log` for errors |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - See [LICENSE](LICENSE) file for details.

**Additional Documentation:**

- [NOTICE](NOTICE) - Project background and development history
- [SECURITY_CLEARANCE.md](SECURITY_CLEARANCE.md) - Guidance for cleared personnel

---

## Acknowledgments

- Built with [Splunk UCC Framework](https://splunk.github.io/addonfactory-ucc-generator/)
- eMASS API integration for federal compliance management
- SuhLabs - Security and Compliance Solutions

---

## Support

For issues, questions, or contributions:

- **GitHub Issues**: [Report a bug](https://github.com/JohnYoungSuh/TA-suhlabs-eMASS/issues)
- **Documentation**: See `LESSONS_LEARNED.md` for development insights
