FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y -q \
    apt-utils \
    tzdata \
    wget \
    git \
    unzip \
    zip \
    tar \
    vim \
    curl \
    gcc \
    fd-find \
    libssl-dev \
    pkg-config \
    build-essential \
    jq \
    software-properties-common \
    python3-pip \
    xsel \
    nodejs \
    npm

# timezone
RUN ln -fs /usr/share/zoneinfo/Azia/Tokyo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# copy postCreateCommand
COPY ./entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# copy shell to exec cargo compete new
COPY ./new.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/new.sh

# copy shell to exec cargo compete submit
COPY ./submit.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/submit.sh

# user setting
USER $UID:$GID
ENV HOME=/workspaces
WORKDIR ${HOME}
RUN chmod -R ugo+wrx ${HOME}
COPY bash.bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc

# for visualizer
RUN npm install -g n
RUN n lts
RUN apt purge -y nodejs npm
RUN apt autoremove -y
RUN npm install -g yarn

# starship
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes
COPY starship.toml ${HOME}/.config/starship.toml

# miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py311_23.11.0-2-Linux-x86_64.sh && \
    bash Miniconda3-py311_23.11.0-2-Linux-x86_64.sh -b -p /opt/miniconda3 && \
    rm -r Miniconda3-py311_23.11.0-2-Linux-x86_64.sh
# 修正: ENVを '=' で繋ぐ形式に変更
ENV PATH="/opt/miniconda3/bin:${PATH}"

# install python package with conda
# ipython kernel for jupyter
RUN conda config --set solver classic

# 修正: seabornにチャンネルを指定。さらに高速化のためインストールを1つにまとめる
RUN conda install -n base ipykernel --update-deps --force-reinstall -y && \
    conda install -c conda-forge -c plotly -y \
    seaborn \
    plotly \
    nbformat \
    python-kaleido \
    optuna \
    statsmodels \
    scikit-learn \
    scipy

# install python package with pip
RUN pip install --upgrade pip && \
    pip install \
    pulp \
    japanize-matplotlib \
    ray[default]
RUN pip install --user online-judge-tools

# Rust
# 修正: ENVを '=' で繋ぐ形式に変更
ENV RUST_HOME="/usr/local/lib/rust"
ENV RUSTUP_HOME="${RUST_HOME}/rustup"
ENV CARGO_HOME="${RUST_HOME}/cargo"

RUN mkdir /usr/local/lib/rust && \
    chmod 0755 $RUST_HOME
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > ${RUST_HOME}/rustup.sh \
    && chmod +x ${RUST_HOME}/rustup.sh \
    && ${RUST_HOME}/rustup.sh -y --default-toolchain 1.70.0 --no-modify-path
# 修正: ENVを '=' で繋ぐ形式に変更
ENV PATH="${PATH}:${CARGO_HOME}/bin"

# wasm
RUN curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

# crates
RUN rustup install stable
RUN cargo +stable install eza
RUN cargo +stable install bat
RUN cargo +stable install cargo-compete
RUN cargo +stable install cargo-edit
RUN cargo +stable install cargo-snippet --features="binaries"
RUN rustup component add rustfmt
