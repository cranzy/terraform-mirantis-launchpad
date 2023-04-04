#!/bin/bash

until $(sudo journalctl | grep -q "Final stage of the Mirantis terraform startup script") ; do
    echo "Waiting for startup scripts to finish..."
    sleep 2
done
echo "Startup scripts have finished."
