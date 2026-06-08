#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_BIN="${HOME}/.local/bin/lark-feishu-listener"
CONFIG_DIR="${HOME}/.config/lark-bot"
CONFIG_FILE="${CONFIG_DIR}/listener.env"
SYSTEMD_DIR="${HOME}/.config/systemd/user"
SERVICE_NAME="lark-feishu-listener.service"

echo "==> Installing listener script"
mkdir -p "${HOME}/.local/bin" "${CONFIG_DIR}" "${HOME}/.local/log/lark-bot"
install -m 755 "${REPO_ROOT}/scripts/lark-feishu-listener" "${INSTALL_BIN}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "==> Creating ${CONFIG_FILE} from example"
  cp "${REPO_ROOT}/config/listener.env.example" "${CONFIG_FILE}"
  echo "    Edit ${CONFIG_FILE} before starting the service."
else
  echo "==> Keeping existing ${CONFIG_FILE}"
fi

echo "==> Installing systemd user service"
mkdir -p "${SYSTEMD_DIR}"
sed "s|%h|${HOME}|g" "${REPO_ROOT}/systemd/lark-feishu-listener.service" > "${SYSTEMD_DIR}/${SERVICE_NAME}"

# Append LARK_CLI to PATH in unit if set in env file
if grep -q '^LARK_CLI=' "${CONFIG_FILE}" 2>/dev/null; then
  lark_cli_path="$(grep '^LARK_CLI=' "${CONFIG_FILE}" | cut -d= -f2- | tr -d '"')"
  if [[ -n "${lark_cli_path}" ]]; then
    lark_bin_dir="$(dirname "${lark_cli_path}")"
    if ! grep -q '^Environment=PATH=' "${SYSTEMD_DIR}/${SERVICE_NAME}"; then
      sed -i "/^EnvironmentFile=/a Environment=PATH=${lark_bin_dir}:/usr/local/bin:/usr/bin:/bin" \
        "${SYSTEMD_DIR}/${SERVICE_NAME}"
    fi
  fi
fi

systemctl --user daemon-reload

if command -v loginctl >/dev/null 2>&1; then
  if [[ "$(loginctl show-user "$(id -un)" -p Linger --value 2>/dev/null || echo no)" != "yes" ]]; then
    echo "==> Enabling systemd user linger (requires sudo)"
    sudo loginctl enable-linger "$(id -un)" || true
  fi
fi

echo
echo "Installed."
echo "  1. Edit ${CONFIG_FILE}"
echo "  2. systemctl --user enable --now lark-feishu-listener"
echo "  3. Send 'ping' to your Feishu CLI bot in a private chat"
