# Python Ecosystem

> Part of [`src/cmds/`](../README.md) — see also [docs/contributing/TECHNICAL.md](../../../docs/contributing/TECHNICAL.md)

## Specifics

- `pytest_cmd.rs` uses a state machine text parser (no JSON available from pytest)
- `scripts/test-pytest-compat.sh` manually exercises pytest directory collection,
  including partial and fatal import failures; captured pytest 8/Python 3.10 and
  pytest 9/Python 3.14 output fixtures provide fast compatibility coverage in
  the regular Rust unit suite
- `ruff_cmd.rs` uses JSON for check mode (`--output-format=json`) and text filtering for format mode
- `pip_cmd.rs` auto-detects `uv` as a pip alternative and routes accordingly
- `python -m pytest` and `python3 -m mypy` are rewritten by the hook registry to `rtk pytest` / `rtk mypy`

## Cross-command

- `ruff_cmd` is called by `cmds/js/lint_cmd` and `cmds/system/format_cmd` for Python projects
- `mypy_cmd` is called by `cmds/js/lint_cmd` when detecting Python type checking
