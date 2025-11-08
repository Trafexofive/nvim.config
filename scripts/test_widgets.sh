#!/bin/bash
# Test widget system

cd /home/mlamkadm/.config/nvim

nvim -c "lua require('mlamkadm.core.widgets').setup(); require('mlamkadm.core.widgets').open('system')"
