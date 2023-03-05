#!/bin/bash

tmux new-session -s migration \
    \; split-window 'kubectl port-forward db 5432:5432' \
    \; split-window 'kubectl port-forward redis 6379:6379' \
    \; select-layout main-horizontal \
    \; select-pane -D
