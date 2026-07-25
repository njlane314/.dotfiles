PACKAGES ?= $(shell sed -e '/^[[:space:]]*$$/d' packages/stow)

.PHONY: check
check:
	./tests/check.sh

.PHONY: packages
packages:
	./bootstrap/bootstrap.sh

.PHONY: bootstrap
bootstrap: packages

.PHONY: install
install:
	./install.sh $(PACKAGES)

.PHONY: vim-plug
vim-plug:
	curl -fLo "$$HOME/.vim/autoload/plug.vim" --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

.PHONY: vim-plugins
vim-plugins:
	vim +PlugInstall +qall

.PHONY: emacs-packages
emacs-packages:
	emacs --batch -l "$$HOME/.emacs.d/init.el" \
		--eval '(message "Emacs packages installed")'

.PHONY: tmux-reload
tmux-reload:
	tmux source-file "$$HOME/.tmux.conf"
