PACKAGES ?= vim cpp

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
