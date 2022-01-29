#!/bin/bash

BIN_DIR="$HOME/.local/bin"

APP_LAUNCHERS=(
	"idea.sh"
	"pycharm.sh"
	"studio.sh"
	"rider.sh"
	"goland.sh"
)

APP_DIRS=$(find $HOME/.local/share/JetBrains/Toolbox/apps -maxdepth 4 -type d -name "bin" | sort)

for dir in $APP_DIRS; do
   for app in "${APP_LAUNCHERS[@]}"; do
   		if [[ -e "$dir/$app" ]]; then
   			echo -e "#!/bin/sh\n\"$dir/$app\"" '"$@"' > "$BIN_DIR/$app"
   			chmod +x "$BIN_DIR/$app"
   		fi
   done
done
