# Feishu Bot Listener

Run a always-on listener on Linux servers so you can **command machines from Feishu** via the official [lark-cli](https://github.com/larksuite/cli) bot.

Designed for **one bot per machine** (private chat only). Each reply includes a `HOST_LABEL` so you can tell which server answered.

## Features

- Listens to **p2p messages** to your Feishu CLI bot (`im.message.receive_v1`)
- Only accepts commands from a configured Feishu user (`ALLOWED_SENDER`)
- Built-in commands: `ping`, `help`, `status`, `run <shell>`
- systemd user service with auto-restart
- Safe for multi-server setup: different `HOST_LABEL` per machine

## Prerequisites

- Linux with systemd (user session)
- Node.js 18+ and [lark-cli](https://www.feishu.cn/feishu-cli):

```bash
npx @larksuite/cli@latest install
```

- Feishu CLI app configured and OAuth completed on this machine:

```bash
lark-cli config init --new
lark-cli auth login --recommend
lark-cli auth status   # note your open_id (ou_xxx)
```

## Quick install

```bash
git clone https://github.com/TAOYUZHOU/feishu-bot-listener.git
cd feishu-bot-listener
./install.sh
```

Edit `~/.config/lark-bot/listener.env`:

```bash
HOST_LABEL=aws-gpu-1
LARK_CLI=/home/you/.nvm/versions/node/v20.20.1/bin/lark-cli   # if using nvm
ALLOWED_SENDER=ou_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
RUN_TIMEOUT_SEC=120
```

Start the service:

```bash
systemctl --user enable --now lark-feishu-listener
systemctl --user status lark-feishu-listener
```

Test in Feishu: open a **private chat** with your CLI bot and send `ping`.

## Commands (Feishu → bot)

| Message | Action |
|---------|--------|
| `ping` | Health check → `pong from <HOST_LABEL>` |
| `help` | List commands |
| `status` | Host uptime, load, disk |
| `run df -h` | Run shell on server (timeout limited) |

## Two machines, two bots

1. On each server: install lark-cli + run `config init` (separate Feishu app per machine)
2. Clone this repo, set a **unique** `HOST_LABEL`
3. Enable the listener service on each machine
4. Use **separate private chats** in Feishu (do not add bots to a group)

## Logs & management

```bash
journalctl --user -u lark-feishu-listener -f
tail -f ~/.local/log/lark-bot/listener.log

systemctl --user restart lark-feishu-listener
lark-cli event status
```

## Security notes

- **Private chat only** — listener filters `chat_type==p2p` and your `open_id`
- `run` executes real shell commands — use only on trusted servers
- Do not commit `listener.env` (contains your open_id)
- Official guidance: treat the CLI bot as a personal assistant; avoid group chats

## Repository layout

```
scripts/lark-feishu-listener   # main listener (Python 3)
config/listener.env.example    # config template
systemd/lark-feishu-listener.service
install.sh                     # install to ~/.local/bin + systemd user
```

## License

MIT
