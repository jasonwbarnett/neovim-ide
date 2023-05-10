FROM centos:centos7 as build

# Ensure updated base
RUN yum update -y

# Enable extra repos
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN rpm -Uvh https://repo.ius.io/ius-release-el7.rpm
RUN yum install -y centos-release-scl centos-release-scl-rh

#12 3.264 No package powerline-fonts available.
#12 3.348 No package ripgrep available.
#12 3.371 No package RUN available.
#12 3.530 No package install available.

# Install core tools
RUN yum install -y ack \
                   bind-utils \
                   curl \
                   devtoolset-11-gcc \
                   devtoolset-11-gcc-c++ \
                   fasd \
                   gcc \
                   git236 \
                   iputils \
                   make \
                   ncurses-devel \
                   telnet \
                   unzip \
                   wget

# Use devtoolset 11 for compiling, etc
ENV PATH=/opt/rh/devtoolset-11/root/usr/bin${PATH:+:${PATH}}
ENV MANPATH=/opt/rh/devtoolset-11/root/usr/share/man${MANPATH:+:${MANPATH}}
ENV INFOPATH=/opt/rh/devtoolset-11/root/usr/share/info${INFOPATH:+:${INFOPATH}}
ENV PCP_DIR=/opt/rh/devtoolset-11/root
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-11/root$rpmlibdir/dyninst$dynpath64$dynpath32${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-11/root$rpmlibdir$rpmlibdir64$rpmlibdir32${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV PKG_CONFIG_PATH=/opt/rh/devtoolset-11/root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}

RUN curl -L https://sourceforge.net/projects/zsh/files/zsh/5.9/zsh-5.9.tar.xz/download -o zsh-5.9.tar.xz && \
    tar xf zsh-5.9.tar.xz && \
    pushd zsh-5.9 && \
    ./configure --with-tcsetpgrp && \
    make && \
    make install && \
    popd && \
    rm -rf zsh-5.9.tar.gz zsh-5.9

# Zsh Configuration
RUN chsh -s /usr/local/bin/zsh root

## Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

## Install fzf
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
    ~/.fzf/install --all

## Install powerlevel10k
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
RUN sed -ri 's@^ZSH_THEME=.*@ZSH_THEME="powerlevel10k/powerlevel10k"@g' ~/.zshrc
RUN curl -LO https://github.com/romkatv/gitstatus/releases/download/v1.5.4/gitstatusd-linux-x86_64.tar.gz && \
    mkdir -p ~/.cache/gitstatus && \
    tar zxf gitstatusd-linux-x86_64.tar.gz -C ~/.cache/gitstatus && \
    rm gitstatusd-linux-x86_64.tar.gz

## Drop .zshrc
COPY --chown=root:root --chmod=0644 .zshrc /root/.zshrc
COPY --chown=root:root --chmod=0644 .p10k.zsh /root/.p10k.zsh

## lay down custom configs
RUN curl -L https://raw.githubusercontent.com/jasonwbarnett/dotfiles/master/bash/aliases.sh -o ~/.oh-my-zsh/custom/aliases.zsh
RUN curl -L https://raw.githubusercontent.com/jasonwbarnett/dotfiles/master/git/gitconfig -o ~/.gitconfig
RUN curl -L https://raw.githubusercontent.com/jasonwbarnett/dotfiles/master/git/gitignore -o ~/.gitignore
RUN curl -L https://raw.githubusercontent.com/jasonwbarnett/dotfiles/master/zsh/fasd.zsh -o ~/.oh-my-zsh/custom/fasd.zsh

# Install neovim
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
RUN chmod u+x nvim.appimage
RUN ./nvim.appimage --appimage-extract && \
    rm ./nvim.appimage && \
    mv /squashfs-root /opt/neovim
RUN ln -s /opt/neovim/AppRun /usr/bin/nvim

# Install nvim config
RUN mkdir -p ~/.config
RUN git clone https://github.com/jasonwbarnett/kickstart.nvim.git ~/.config/nvim
RUN nvim --headless "+Lazy! sync" +qa

# Install Python 3.11
RUN yum install -y rh-python38-python-pip rh-python38
#RUN cat /opt/rh/rh-python38/enable >> ~/.bashrc
ENV PATH=/opt/rh/rh-python38/root/usr/local/bin:/opt/rh/rh-python38/root/usr/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH=/opt/rh/rh-python38/root/usr/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV MANPATH=/opt/rh/rh-python38/root/usr/share/man:$MANPATH
ENV PKG_CONFIG_PATH=/opt/rh/rh-python38/root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}
ENV XDG_DATA_DIRS="/opt/rh/rh-python38/root/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3
RUN pip3 install neovim

# Install rustc
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install Ruby 3.1
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.oh-my-zsh/custom/rbenv.zsh
RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
ENV PATH /root/.rbenv/shims:/root/.rbenv/bin:$PATH
## RUN curl -LO http://pyyaml.org/download/libyaml/yaml-0.2.5.tar.gz && \
##     tar zxf yaml-0.2.5.tar.gz && \
##     pushd yaml-0.2.5 && \
##     ./configure && \
##     make && \
##     make install

RUN yum install -y zlib-devel openssl-devel readline-devel zlib-devel libffi-devel libyaml-devel
RUN rbenv install $(rbenv install -l | grep -v -- - | grep '^3.2')
RUN rbenv global $(rbenv install -l | grep -v -- - | grep '^3.2')
RUN echo 'gem: --no-document' >> ~/.gemrc
RUN gem install neovim

# Install golang
RUN yum install -y golang

# Install LSPs
RUN nvim --headless "+LspInstall lua_ls solargraph gopls" +qa

FROM scratch
COPY --from=build / /

ENTRYPOINT ["/usr/local/bin/zsh"]
CMD ["-l"]
