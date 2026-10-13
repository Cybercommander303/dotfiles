set -g fish_greeting

if status is-interactive
    abbr -a .. 'cd ..'
    abbr -a install 'sudo dnf install'
    abbr -a upgrade 'sudo dnf upgrade'
    abbr -a edit nvim
    abbr -a c clear
    abbr -a net 'sudo systemctl restart NetworkManager'
    abbr -a hypr 'cd ~/.config/hypr'
    abbr -a home 'cd ~'
    abbr -a config 'cd ~/.config'
    abbr -a quicks 'cd ~/.config/quickshell/'

end

fish_add_path /home/chamelfernando/.spicetify
