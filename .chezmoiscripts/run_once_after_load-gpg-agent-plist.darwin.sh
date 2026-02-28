#!/bin/bash
# vim: ft=bash

set -e

# See: https://github.com/drduh/YubiKey-Guide?tab=readme-ov-file#ssh
echo "Launching gpg-agent plists. Please reboot for changes to take effect."
launchctl load ~/Library/LaunchAgents/gnupg.gpg-agent.plist
launchctl load ~/Library/LaunchAgents/gnupg.gpg-agent-symlink.plist
