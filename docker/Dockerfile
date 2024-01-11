FROM ubuntu:22.04

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
    tree \
    gcc \
    fd-find \
    libssl-dev \
    pkg-config \
    build-essential \
    jq \
    software-properties-common

# timezone
RUN ln -fs /usr/share/zoneinfo/Azia/Tokyo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# copy postCreateCommand
COPY ./entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# copy shell to exec cargo compete new
COPY ./cargo_compete_new.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/cargo_compete_new.sh

# user setting
USER $UID:$GID
ENV HOME=/workspace
WORKDIR /workspace
RUN chmod -R ugo+wrx "/workspace"
COPY bash.bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc

# Python
RUN apt-get install -y -q \
    python3-pip \
    python3-launchpadlib
RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y -q \
    python3.10

# miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3 && \
    rm -r Miniconda3-latest-Linux-x86_64.sh
ENV PATH /opt/miniconda3/bin:$PATH

# install python package with conda
# ipython kernel for jupyter
RUN conda install -n base ipykernel --update-deps --force-reinstall -y && \
    # graph drawing tools
    conda install -y seaborn && \
    conda install -c plotly plotly -y && \
    conda install -c conda-forge nbformat -y && \
    conda install -c conda-forge python-kaleido -y && \
    # optuna
    conda install -c conda-forge optuna

# install python package with pip
RUN pip install --upgrade pip && \
    pip install \
    pulp \
    japanize-matplotlib \
    ray[default]

# Rust
ENV RUST_HOME /usr/local/lib/rust
ENV RUSTUP_HOME ${RUST_HOME}/rustup
ENV CARGO_HOME ${RUST_HOME}/cargo
RUN mkdir /usr/local/lib/rust && \
    chmod 0755 $RUST_HOME
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > ${RUST_HOME}/rustup.sh \
    && chmod +x ${RUST_HOME}/rustup.sh \
    && ${RUST_HOME}/rustup.sh -y --default-toolchain 1.70.0 --no-modify-path
ENV PATH $PATH:$CARGO_HOME/bin

RUN cargo install exa
RUN cargo install --locked bat
RUN cargo install cargo-compete
RUN cargo install cargo-edit
RUN cargo install cargo-watch
RUN cargo install cargo-generate
RUN cargo install cargo-snippet --features="binaries"
RUN rustup component add rustfmt
