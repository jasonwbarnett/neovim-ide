FROM ubuntu:22.04

RUN apt update && apt upgrade -y

# Install core tools
RUN apt install -y curl \
                   git \
		   build-essential

# Install neovim
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
RUN chmod u+x nvim.appimage
RUN ./nvim.appimage --appimage-extract
RUN mv /squashfs-root /opt/neovim
RUN ln -s /opt/neovim/AppRun /usr/bin/nvim

# Install nvim config
RUN mkdir -p ~/.config
RUN git clone https://github.com/jasonwbarnett/kickstart.nvim.git ~/.config/nvim
RUN nvim --headless "+Lazy! sync" +qa

# Install Python 3.11
RUN apt install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt-get install python3.11 python3.11-distutils -y
RUN ln -sf $(which python3.11) /usr/bin/python3
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11
RUN echo 'alias vi=nvim' >> ~/.bashrc
RUN echo 'alias vim=nvim' >> ~/.bashrc

# Install Ruby 3.2
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc
RUN git clone https://github.com/rbenv/ruby-build.git /root/.rbenv/plugins/ruby-build
ENV PATH /root/.rbenv/shims:/root/.rbenv/bin:$PATH
RUN apt install zlib1g-dev libyaml-dev libssl-dev -y
RUN rbenv install $(rbenv install -l | grep -v -- - | grep '^3.2')
RUN rbenv global $(rbenv install -l | grep -v -- - | grep '^3.2')
RUN echo 'gem: --no-document' >> ~/.gemrc
# Ruby LSP
RUN gem install solargraph
