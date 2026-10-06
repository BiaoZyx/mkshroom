if [ -f /etc/profile ]; then
    . /etc/profile
fi

if [ -f /etc/mkshrc ]; then
    . /etc/mkshrc
fi

if [ -f "$HOME/.mkshrc" ]; then
    . "$HOME/.mkshrc"
fi
