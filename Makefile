PACKAGES ?= $(shell sed -e '/^[[:space:]]*$$/d' packages/stow)

.PHONY: check
check:
	./tests/check.sh

.PHONY: packages
packages:
	./bootstrap/bootstrap.sh

.PHONY: packages-dry-run
packages-dry-run:
	./bootstrap/bootstrap.sh --dry-run

.PHONY: bootstrap
bootstrap: packages

.PHONY: install
install:
	./install.sh $(PACKAGES)

.PHONY: install-dry-run
install-dry-run:
	./install.sh --dry-run $(PACKAGES)

.PHONY: apply-visuals
apply-visuals:
	./install.sh --apply-visuals terminal wallpaper

.PHONY: vim-plug
vim-plug:
	@data_home="$${XDG_DATA_HOME:-$$HOME/.local/share}"; \
	case "$$data_home" in /*) ;; *) data_home="$$HOME/.local/share";; esac; \
	curl -fLo "$$data_home/vim/autoload/plug.vim" --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

.PHONY: vim-plugins
vim-plugins:
	vim +PlugInstall +qall

.PHONY: emacs-packages
emacs-packages:
	emacs --batch -Q -L "$$HOME/.emacs.d/lisp" \
		-l dotfiles-packages --eval '(dotfiles/install-packages)'

.PHONY: tmux-reload
tmux-reload:
	tmux source-file "$$HOME/.tmux.conf"
