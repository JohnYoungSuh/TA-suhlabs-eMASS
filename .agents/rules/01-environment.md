# Rule 01 — Execution Environment

## Shell & Environment

- **ALWAYS** run all commands inside WSL Ubuntu via `wsl -d Ubuntu bash -c "..."`.
- **NEVER** use PowerShell, `cmd.exe`, or Windows drive paths (`C:\...`) for project tasks.
- All file paths in commands must use UNIX format: `/home/suhlabs/...` or `~/...`.
- When referencing the workspace from the Windows host, translate:
  - `/Ubuntu/home/suhlabs/...` → `\\wsl$\Ubuntu\home\suhlabs\...` (read/write tools)
  - `/home/suhlabs/...` (WSL shell commands via `wsl -d Ubuntu bash -c`)

## Python Interpreter

- Use `python3.12` (matches `.venv` and `PYTHON` in Makefile).
- Virtual environment is at **project root** `.venv/` — never inside `package/`.
- Activate with: `source .venv/bin/activate`

## PowerShell Quoting Gotcha

- PowerShell destroys single-quotes in `wsl -d Ubuntu bash -c "..."` inline commands.
- For complex Python one-liners, write a temp `.py` file, run it, then delete it.
- Never embed Python `if`/`else`/`for` expressions in PowerShell `wsl` one-liners.
