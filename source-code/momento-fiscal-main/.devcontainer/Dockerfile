#############################
#    Ruby on Rails setup    #
#############################

# [Choice] Ruby version: 3, 3.0, 2, 2.7, 2.6
ARG VARIANT="3"
FROM mcr.microsoft.com/devcontainers/ruby:${VARIANT}

# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="lts/*"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# Install dependencies
RUN apt update
# Ruby API
RUN apt install -y postgresql-client postgresql-contrib libpq-dev libvips libvips-tools ffmpeg mupdf mupdf-tools poppler-utils
# Electron APP
RUN apt install -y libdbus-1-3 libnss3 libasound2 libatk-adaptor libcups2 libgtk-3-0 libgbm1

# Install ruby dependencies
RUN gem install bundler rubocop rubocop-performance rubocop-rails rubocop-rspec
RUN chown -R 1000:1000 /usr/local/rvm/gems/

##########################
#    Dart and Flutter    #
##########################

# Locale
ENV LANG C.UTF-8

# OpenJDK
RUN apt install -y openjdk-17-jdk-headless wget git xz-utils zip unzip libglu1-mesa --no-install-recommends

# Android SDK
ENV ANDROID_SDK_TOOLS_VERSION=11076708
ENV ANDROID_PLATFORM_VERSION=33
ENV ANDROID_BUILD_TOOLS_VERSION=33.0.0
ENV ANDROID_HOME=/android-sdk-linux
ENV ANDROID_SDK_ROOT="$ANDROID_HOME"
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && curl -C - --output android-sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip \
    && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME}/cmdline-tools \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm android-sdk-tools.zip \
    && yes | sdkmanager --licenses \
    && sdkmanager platform-tools \
    && sdkmanager emulator \
    && sdkmanager "platforms;android-${ANDROID_PLATFORM_VERSION}" "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    && sdkmanager --install "cmdline-tools;latest"

# Flutter SDK
ENV FLUTTER_CHANNEL="stable"
ENV FLUTTER_VERSION="3.35.5"
ENV FLUTTER_HOME=/flutter
ENV PATH=${PATH}:${FLUTTER_HOME}/bin

RUN curl -C - --output flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz \
    && mkdir -p ${FLUTTER_HOME}/ \
    && tar -xf flutter.tar.xz -C / \
    && rm flutter.tar.xz

# Adicionar usuário vscode
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN if ! id -u $USERNAME > /dev/null 2>&1; then \
    groupadd --gid $USER_GID $USERNAME && \
    useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME; \
    fi

# Ajustar permissões
RUN chown -R $USERNAME:$USERNAME ${FLUTTER_HOME} ${ANDROID_HOME} /home/$USERNAME

# Configurações do Flutter
USER vscode
RUN flutter config --android-sdk "${ANDROID_SDK_ROOT}" \
    && yes | flutter doctor --android-licenses \
    && flutter config --no-analytics

# Dependências adicionais para o Flutter
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev

# Execute flutter doctor e cache os artefatos
RUN flutter doctor -v \
    && flutter precache

# Clean Up
RUN sudo apt-get autoremove -y \
    && sudo apt-get clean -y \
    && sudo rm -rf /var/lib/apt/lists/*
