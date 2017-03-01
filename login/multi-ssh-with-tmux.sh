#!/bin/sh
window=$1
proxy=$2
hosts=`echo $3 | tr ',' ' '`

if [ -z "$hosts" ] || [ -z "$window" ]; then
  exit 1
fi

### tmuxのセッションを作成
session=multi-ssh-`date +%s`
tmux new -d -n $window -s $session

### 各ホストにsshログイン
i=0
for host in $hosts; do
  i=$(($i + 1))
  if [ $i -eq 1 ]; then
    tmux send-keys "ssh -t ${proxy} 'ssh -o StrictHostKeyChecking=no ${host}'" C-m
  else
    sleep 0.1
    tmux split-window
    tmux select-layout tiled
    tmux send-keys "ssh -t ${proxy} 'ssh -o StrictHostKeyChecking=no ${host}'" C-m
  fi
done

### 最初のpaneを選択状態にする
tmux select-pane -t 0

### paneの同期モードを設定
tmux set-window-option synchronize-panes on

### セッションにアタッチ
tmux attach-session -t $session
