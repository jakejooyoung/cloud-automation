# Custom bash script for ec2 instance
blue=$"\033[38;5;39m"
green=$"\033[38;5;48m"
darkgrey=$"\033[38;5;236m"
yellow=$"\033[38;5;11m"
fontgrey=$"\033[38;5;8m"
envcolor=$blue

# Colored prompts
PS1="\[${envcolor}\]┌─\u \[$(tput sgr0)\]\[${darkgrey}\] at \h in \[$(tput sgr0)\]\[${yellow}\] \w \[$(tput sgr0)\]\n\[${envcolor}\]└─$\[$(tput sgr0)\]"

# Alias commands
# alias restart-server="sudo service httpd restart"
# alias restart-sql="sudo service mysqld restart"
# alias phpmyadmin="cd /var/www/html/phpmyadmin"
alias editbash="vi $HOME/.bash_aliases"
alias reload="source $HOME/.bash_aliases"
alias ..="cd ../"