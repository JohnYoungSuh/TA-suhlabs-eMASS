# TA-securepro-eMASS

## Setup
```bash
make preflight
make setup
```

## Build
```bash
make build
make validate
```

## Test
```bash
make test-unit
make test-smoke
```

## Image
```bash
make image
docker-compose up -d
```

## Access
- URL: http://localhost:8000
- User: admin
- Pass: Password123!

## Troubleshooting
- Permission errors: Run `chmod` or `chown` commands manually
- Build recursion: Check `.uccignore` includes `output/`
- Git sync: Run `git add/commit/push` manually when ready
