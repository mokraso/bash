#!/bin/bash

# Start applications on specific workspaces
i3-msg 'workspace 1; exec your-terminal'
sleep 2
i3-msg 'workspace 2; exec firefox'
sleep 2
i3-msg 'workspace 3; exec zed'
sleep 2
i3-msg 'workspace 4; exec evolution'
sleep 1
i3-msg 'workspace 1'

