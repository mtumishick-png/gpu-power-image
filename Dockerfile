FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git vim tmux htop nano unzip jq \
    openssh-server \
    xfce4 xfce4-goodies xrdp dbus-x11 \
    python3 python3-pip python3-venv \
    software-properties-common \
    gnupg lsb-release ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN install -d /usr/share/keyrings \
    && curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
       | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" \
       > /etc/apt/sources.list.d/cloudflare-client.list \
    && apt-get update && apt-get install -y cloudflare-warp \
    && rm -rf /var/lib/apt/lists/*

RUN dpkg --add-architecture i386 \
    && echo "deb http://archive.ubuntu.com/ubuntu jammy multiverse" > /etc/apt/sources.list.d/multiverse.list \
    && apt-get update && apt-get install -y --no-install-recommends steam \
    && rm -rf /var/lib/apt/lists/*

RUN (SUN_URL=$(curl -s https://api.github.com/repos/LizardByte/Sunshine/releases/latest | jq -r '.assets[] | select(.name | test("ubuntu-22.04-amd64.deb$")) | .browser_download_url' | head -1) \
    && if [ -n "$SUN_URL" ] && [ "$SUN_URL" != "null" ]; then \
         wget -qO /tmp/sunshine.deb "$SUN_URL" && apt-get install -y /tmp/sunshine.deb && rm /tmp/sunshine.deb; \
       else echo "WARNING: Sunshine asset not found, skipping"; fi) || echo "WARNING: Sunshine install skipped"

RUN (wget -qO /tmp/parsec.deb "https://builds.parsec.app/parsec-linux.deb" \
    && apt-get install -y /tmp/parsec.deb \
    && rm /tmp/parsec.deb) || echo "WARNING: Parsec install skipped"

RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/UsePAM yes/UsePAM yes/' /etc/ssh/sshd_config

RUN echo "startxfce4" > /root/.xsession \
    && sed -i 's/^max_bpp=32/max_bpp=24/' /etc/xrdp/xrdp.ini \
    && sed -i 's/^port=3389/port=3389/' /etc/xrdp/xrdp.ini

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 3389 47984 47989 47990

ENTRYPOINT ["/entrypoint.sh"]
