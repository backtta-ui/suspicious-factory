FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip python3 && rm -rf /var/lib/apt/lists/*
ARG GODOT_VERSION=4.6.3
RUN curl -fL --retry 3 "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o /tmp/godot.zip && unzip /tmp/godot.zip -d /tmp/godot && mv /tmp/godot/Godot* /usr/local/bin/godot && chmod +x /usr/local/bin/godot && rm -rf /tmp/godot /tmp/godot.zip
WORKDIR /app
COPY . /app
ENV XDG_DATA_HOME=/tmp/godot-data XDG_CONFIG_HOME=/tmp/godot-config XDG_CACHE_HOME=/tmp/godot-cache
RUN godot --headless --editor --path /app --import --quit && chmod +x /app/server/entrypoint.sh
EXPOSE 10000
CMD ["/app/server/entrypoint.sh"]
