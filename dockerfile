FROM ubuntu:latest as base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


RUN set -ex \
  && apt-get update \
  # install dependencies
  && apt-get install --yes --no-install-recommends  ca-certificates \
  build-essential sudo curl wget  python3 python3.12-venv git  zsh  neovim ninja-build gettext libtool libtool-bin autoconf automake \
  cmake g++ pkg-config unzip nodejs npm luarocks cargo clang snapd\
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install FZF - executable only (required for zsh-interactive-cd)
RUN \
  FZF_VERSION="0.21.1" \
  && FZF_DOWNLOAD_SHA256="7d4e796bd46bcdea69e79a8f571be1da65ae9d9cc984b50bc4af5c0b5754fbd5" \
  && wget -nv -O fzf.tgz https://github.com/junegunn/fzf-bin/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tgz \
  && echo "$FZF_DOWNLOAD_SHA256 fzf.tgz" | sha256sum -c - \
  && tar zxvf fzf.tgz --directory /usr/local/bin \
  && rm fzf.tgz

# install Fira Code from Nerd fonts
RUN \
  NERDS_FONT_VERSION="2.1.0" \
  && FONT_DIR=/usr/local/share/fonts \
  && FIRA_CODE_URL=https://github.com/ryanoasis/nerd-fonts/raw/${NERDS_FONT_VERSION}/patched-fonts/FiraCode \
  && FIRA_CODE_LIGHT_DOWNLOAD_SHA256="5e0e3b18b99fc50361a93d7eb1bfe7ed7618769f4db279be0ef1f00c5b9607d6" \
  && FIRA_CODE_REGULAR_DOWNLOAD_SHA256="3771e47c48eb273c60337955f9b33d95bd874d60d52a1ba3dbed924f692403b3" \
  && FIRA_CODE_MEDIUM_DOWNLOAD_SHA256="42dc83c9173550804a8ba2346b13ee1baa72ab09a14826d1418d519d58cd6768" \
  && FIRA_CODE_BOLD_DOWNLOAD_SHA256="060d4572525972b6959899931b8685b89984f3b94f74c2c8c6c18dba5c98c2fe" \
  && FIRA_CODE_RETINA_DOWNLOAD_SHA256="e254b08798d59ac7d02000a3fda0eac1facad093685e705ac8dd4bd0f4961b0b" \
  && mkdir -p $FONT_DIR \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Light/complete/Fura%20Code%20Light%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Regular/complete/Fura%20Code%20Regular%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Medium/complete/Fura%20Code%20Medium%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Bold/complete/Fura%20Code%20Bold%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Retina/complete/Fura%20Code%20Retina%20Nerd%20Font%20Complete.ttf \
  && echo "$FIRA_CODE_LIGHT_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Light Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_REGULAR_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Regular Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_MEDIUM_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Medium Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_BOLD_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Bold Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_RETINA_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Retina Nerd Font Complete.ttf" | sha256sum -c -

ENV APP_USER=kuldeeps
ENV APP_USER_GROUP=kuldeeps
ARG APP_USER_HOME=/home/$APP_USER
ARG NVIM_CONFIG_DIR=$APP_USER_HOME/.config/nvim
ARG NVIM_DIR=$APP_USER_HOME/tools/nvim

RUN useradd -m  -s /bin/bash $APP_USER
RUN usermod -aG sudo $APP_USER && echo "kuldeeps ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN chmod 0440 /etc/sudoers

USER $APP_USER
WORKDIR $APP_USER_HOME

# install oh-my-zsh
RUN wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | zsh || true

ARG ZSH_CUSTOM=$APP_USER_HOME/.oh-my-zsh/custom

# install oh-my-zsh plugins and theme
RUN \
  ZSH_PLUGINS=$ZSH_CUSTOM/plugins \
  && ZSH_THEMES=$ZSH_CUSTOM/themes \
  && git clone --single-branch --branch '0.7.1' --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_PLUGINS/zsh-syntax-highlighting \
  && git clone --single-branch --branch 'v0.6.4' --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_PLUGINS/zsh-autosuggestions \
  && git clone --single-branch --depth 1 https://github.com/romkatv/powerlevel10k.git $ZSH_THEMES/powerlevel10k

# install gitstatus
RUN \
  GITSTATUS_VERSION="1.0.0" \
  && GITSTATUS_SHA256="e33867063f091d3c31ede9916fef079ff8cd6fdcc70d051914f962ab3b8f36fd" \
  && wget -nv -O gitstatus.tgz https://github.com/romkatv/gitstatus/releases/download/v${GITSTATUS_VERSION}/gitstatusd-linux-x86_64.tar.gz \
  && echo "$GITSTATUS_SHA256 gitstatus.tgz" | sha256sum -c - \
  && mkdir -p ./.cache/gitstatus \
  && tar zxvf gitstatus.tgz --directory ./.cache/gitstatus \
  && rm gitstatus.tgz

# install oh-my-zsh config files
COPY --chown=$APP_USER:$APP_USER_GROUP ./config/.zshrc ./config/.p10k.zsh $APP_USER_HOME/

#RUN git clone https://github.com/kuldeepsingh/nvim-config.git $APP_USER_HOME/.config/nvim
RUN  rm -rf $APP_USER_HOME/.config/nvim

RUN git clone https://github.com/neovim/neovim.git && cd neovim && make CMAKE_BUILD_TYPE=Release && sudo make install

ENV TERM=xterm-256color

# we must change locale to UTF-8, or zplug install will fail
ENV LC_ALL en_US.UTF-8

CMD ["zsh"]
