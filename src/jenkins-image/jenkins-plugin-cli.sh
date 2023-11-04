#!/bin/bash
jenkins-plugin-cli --list 2>&1 | grep -A5000 "Installed plugins" | grep -B5000 "Bundled plugins" | grep -v " plugins" | awk '{print $1}' > plugins_to_update.txt
jenkins-plugin-cli --latest --plugin-file plugins_to_update.txt