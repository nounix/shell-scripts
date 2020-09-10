#!/bin/bash

echo -e "#!/bin/sh\n\"$HOME/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox\"" '"$@"' >"$HOME/.local/bin/jetbrains-toolbox.sh"
chmod +x "$HOME/.local/bin/jetbrains-toolbox.sh"
URL="https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
URL=$(curl -s "$URL" | grep -E -o "linux\":{\"link\":\"[^\"]+" | sed 's/.*https/https/')
if [[ ! -z "$URL" ]]; then
    wget "$URL" -O - | tar xz -C /tmp/ --strip 1
    /tmp/jetbrains-toolbox
fi
