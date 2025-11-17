1. add the script to quick action:

workflow receives current folders in finder
shell: /bin/zsh
pass input as arguments
~/bin/copy_folder_contents.sh "$1"

also add ~/bin as $PATH in env