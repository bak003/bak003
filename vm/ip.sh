ip addr | grep 'inet ' | grep -Ev 'inet 127|inet 192\.168' | sed "s/[[:space:]]*inet \([0-9.]*\)\/.*/\1/"
