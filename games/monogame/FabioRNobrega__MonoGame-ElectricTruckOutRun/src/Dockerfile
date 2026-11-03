# syntax=docker/dockerfile:1.7
FROM mcr.microsoft.com/dotnet/sdk:10.0.302-noble

ARG MONOGAME_VERSION=3.8.4.1

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DOTNET_CLI_HOME=/opt/dotnet-cli \
    NUGET_PACKAGES=/nuget/packages \
    MGFXC_WINE_PATH=/opt/winemonogame \
    LIBGL_ALWAYS_SOFTWARE=1

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        libfontconfig1 \
        libfreetype6 \
        libgl1 \
        libgl1-mesa-dri \
        libglx-mesa0 \
        libopenal1 \
        libsdl2-2.0-0 \
        libudev1 \
        mesa-utils \
        novnc \
        openbox \
        p7zip-full \
        websockify \
        wine \
        wine64 \
        x11-utils \
        x11vnc \
        xvfb \
    && rm -rf /var/lib/apt/lists/*

ARG MGFXC_SETUP_SHA256=eb12e211de95b2ba71b5bfbc2a0ed187dad515336e52e5b253b2b2209cf27ecd

RUN mkdir -p /opt/dotnet-cli /nuget/packages \
    && dotnet new install "MonoGame.Templates.CSharp@${MONOGAME_VERSION}" \
    && curl --fail --silent --show-error --location \
        https://monogame.net/downloads/net8_mgfxc_wine_setup.sh \
        --output /tmp/net8_mgfxc_wine_setup.sh \
    && echo "${MGFXC_SETUP_SHA256}  /tmp/net8_mgfxc_wine_setup.sh" | sha256sum --check --strict \
    && xvfb-run --auto-servernum bash /tmp/net8_mgfxc_wine_setup.sh \
    && mv /root/.winemonogame /opt/winemonogame \
    && rm -f /tmp/net8_mgfxc_wine_setup.sh /root/.profile /root/.zprofile \
    && chmod -R a+rwX /opt/dotnet-cli /nuget/packages /opt/winemonogame /usr/share/dotnet

WORKDIR /workspace

CMD ["bash"]
