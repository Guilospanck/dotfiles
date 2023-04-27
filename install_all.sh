echo "Installing Brew..."
sh ./brew/install.sh

echo "Installing zsh..."
sh ./zsh/install.sh

echo "Installing Node..."
sh ./node/install.sh

echo "Installing Rust..."
sh ./rust/install.sh

echo "Installing Go..."
sh ./go/install.sh

echo "Installing Fig..."
sh ./fig/install.sh

echo "Installing Colima and Dive..."
sh ./docker/install.sh

echo "Installing kubectl, helm and minikube..."
sh ./k8s/install.sh

echo "Installing Misc..."
sh ./misc/install.sh

echo "\n==================================="
echo "REMINDERS:

- Configure ~/.fig/settings.json
- Configure ~/.zshrc
- Install GUI applications
- Install VsCode recommended extensions
- Configure .gitconfig"