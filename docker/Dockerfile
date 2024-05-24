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
    tree \
    gcc \
    fd-find \
    libssl-dev \
    pkg-config \
    build-essential \
    jq \
    software-properties-common \
    python3-pip

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

# miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py311_23.11.0-2-Linux-x86_64.sh && \
    bash Miniconda3-py311_23.11.0-2-Linux-x86_64.sh -b -p /opt/miniconda3 && \
    rm -r Miniconda3-py311_23.11.0-2-Linux-x86_64.sh
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
    conda install -c conda-forge optuna -y && \
    # ML
    conda install -c conda-forge statsmodels -y && \
    conda install -c conda-forge scikit-learn -y && \
    conda install -c conda-forge scipy -y

# install python package with pip
RUN pip install --upgrade pip && \
    pip install \
    pulp \
    japanize-matplotlib \
    ray[default]
RUN pip install --user online-judge-tools

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
RUN cargo install bat --locked
RUN cargo install cargo-compete --locked
RUN cargo install cargo-edit --locked
RUN cargo install cargo-snippet --features="binaries"
RUN rustup component add rustfmt