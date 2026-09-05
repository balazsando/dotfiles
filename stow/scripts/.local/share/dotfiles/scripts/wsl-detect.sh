#!/usr/bin/env bash
# wsl-detect.sh — source this file to get is_wsl()
is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }
