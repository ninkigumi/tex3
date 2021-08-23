# Copyright (c) 2021 Shigemi ISHIDA
# Released under the MIT license
# https://opensource.org/licenses/MIT

FROM alpine:3.13

ARG GLIBC_VER=2.33
ARG TEXLIVE_VER=2021

ENV LANG=C.UTF-8
ENV GLIBC_URL_BASE=https://github.com/pman0214/docker-glibc-builder/releases/download
ENV PATH=/usr/local/texlive/${TEXLIVE_VER}/bin/x86_64-linux:/usr/local/texlive/${TEXLIVE_VER}/bin/aarch64-linux:$PATH

RUN set -x && \
    cd / && \
    apk update && \
    apk add --no-cache --virtual .fetch-deps curl xz && \
    apk add --no-cache --virtual .glibc-bin-deps libgcc && \
    apk add --no-cache perl fontconfig-dev freetype-dev ghostscript && \
    curl -L ${GLIBC_URL_BASE}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}-$(arch).tar.gz | \
      tar zx -C / && \
    mkdir -p /lib64 /usr/glibc-compat/lib/locale /usr/glibc-compat/lib64 && \
    #cp /tmp/files/ld.so.conf /usr/glibc-compat/etc/ && \
    #cp /tmp/files/nsswitch.conf /etc/ && \
    { \
      echo '/usr/local/lib'; \
      echo '/usr/glibc-compat/lib'; \
      echo '/usr/lib'; \
      echo '/lib'; \
     } | tee /usr/glibc-compat/etc/files/ld.so.conf && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' > /etc/nsswitch.conf && \
    rm -rf /usr/glibc-compat/etc/rpc && \
    rm -rf /usr/glibc-compat/lib/gconv && \
    rm -rf /usr/glibc-compat/lib/getconf && \
    rm -rf /usr/glibc-compat/lib/audit && \
    rm -rf /usr/glibc-compat/var && \
    for l in /usr/glibc-compat/lib/ld-linux-*; do \
      ln -s $l /lib/$(basename $l); \
      ln -s $l /usr/glibc-compat/lib64/$(basename $l); \
      ln -s $l /lib64/$(basename $l); \
    done && \
    if [ -f /etc/ld.so.cache ]; then \
      rm -f /etc/ld.so.cache; \
    fi && \
    ln -s /usr/glibc-compat/etc/ld.so.cache /etc/ld.so.cache && \
    /usr/glibc-compat/sbin/ldconfig && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "${LANG}" || true && \
    echo "export LANG=${LANG}" > /etc/profile.d/locale.sh && \
    rm -rf /usr/glibc-compat/share && \
    rm -rf /usr/glibc-compat/bin && \
    rm -rf /usr/glibc-compat/sbin && \
    mkdir /tmp/install-tl-unx && \
    curl -L ftp://tug.org/historic/systems/texlive/${TEXLIVE_VER}/install-tl-unx.tar.gz | \
      tar zx -C /tmp/install-tl-unx --strip-components=1 && \
    { \
      echo "selected_scheme scheme-full"; \
      echo "tlpdbopt_install_docfiles 0"; \
      echo "tlpdbopt_install_srcfiles 0"; \
      echo "binary_$(arch)-linuxmusl 0"; \
      echo "binary_$(arch)-linux 1"; \
     } | tee /tmp/install-tl-unx/texlive.profile && \
    /tmp/install-tl-unx/install-tl \
      --profile=/tmp/install-tl-unx/texlive.profile && \
    tlmgr install \
      collection-latexextra \
      collection-fontsrecommended \
      collection-langjapanese \
      epstopdf \
      latexmk && \
    apk del --purge .fetch-deps && \
    apk del --purge .glibc-bin-deps && \
    rm -rf /tmp/files && \
    rm -rf /tmp/install-tl-unx && \
    rm -rf /var/cache/apk && \
    mkdir /var/cache/apk

# Set up Japanese fonts
RUN tlmgr repository add http://contrib.texlive.info/current tlcontrib && \
    tlmgr pinning add tlcontrib '*' && \
    tlmgr install \
      collection-latexextra \
      collection-fontsrecommended \
      collection-langjapanese \
      japanese-otf-nonfree \
      japanese-otf-uptex-nonfree \
      ptex-fontmaps-macos \
      cjk-gs-integrate-macos && \
    kanji-config-updmap-sys --force --jis2004 hiragino-highsierra-pron && \
    cjk-gs-integrate --link-texmf --force \
      --fontdef-add=$(kpsewhich -var-value=TEXMFDIST)/fonts/misc/cjk-gs-integrate-macos/cjkgs-macos-highsierra.dat && \
    # Set up hiragino and the other Japanese fonts link.
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ明朝 ProN.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSerif.ttc && \
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ丸ゴ ProN W4.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSansR-W4.ttc && \
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W0.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W0.ttc && \
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W1.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W1.ttc && \
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W2.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W2.ttc && \
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W3.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W3.ttc && \
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W4.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W4.ttc && \
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W5.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W5.ttc && \
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W6.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W6.ttc && \
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W7.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W7.ttc && \
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W8.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W8.ttc && \
    ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W9.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W9.ttc && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/47405a357e3ac82b7afbf33f535962172e3e3d10.asset/AssetData/Osaka.ttf /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/Osaka.ttf && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/eca12ba29af8fda43b3ebe09ae1c0606adc65a27.asset/AssetData/OsakaMono.ttf /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/OsakaMono.ttf && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/a5578564cd8cb162d7ba1544317ef3ae407bf939.asset/AssetData/Klee.ttc /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/Klee.ttc && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/8def8795a8bc5906be76cb45d9ca92ff305adb0f.asset/AssetData/TsukushiAMaruGothic.ttc /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/TsukushiAMaruGothic.ttc && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/6ec5cb139687d842d0186f98215ef1c477df6cc0.asset/AssetData/TsukushiBMaruGothic.ttc /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/TsukushiBMaruGothic.ttc && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/5ef536f846908ec81f4b37caef397b3cb050b64e.asset/AssetData/ToppanBunkyuGothicPr6N.ttc /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/ToppanBunkyuGothicPr6N.ttc && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/d37ed4f492e87221b72d5c3aa5d4ff76e6d37c87.asset/AssetData/ToppanBunkyuMinchoPr6N-Regular.otf /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/ToppanBunkyuMinchoPr6N-Regular.otf && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/c7c8e5cb889b80fff0175bf138a7b66c6f027f21.asset/AssetData/ToppanBunkyuMidashiGothicStdN-ExtraBold.otf /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/ToppanBunkyuMidashiGothicStdN-ExtraBold.otf && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/14a24f75750dfdd5cb190b7d808e8d4731888704.asset/AssetData/ToppanBunkyuMidashiMinchoStdN-ExtraBold.otf /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/ToppanBunkyuMidashiMinchoStdN-ExtraBold.otf && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/bf3dc4579b9aab95801aaba773fc9bb83893b991.asset/AssetData/Kyokasho.ttc /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/Kyokasho.ttc && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/00a83746b65bd0a829eba9a553e88c60b18f89d7.asset/AssetData/YuGothic-Medium.otf /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/YuGothic-Medium.otf && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/16410f7b0c96b4bb08d952fa04d67cd65a42f1b7.asset/AssetData/YuGothic-Bold.otf /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/YuGothic-Bold.otf && \
    ln -s /usr/share/fonts/SystemLibraryAssetsV2/com_apple_MobileAsset_Font6/bdee83ea598d4a36c665b2095e0f39376e9c182b.asset/AssetData/YuMincho.ttc /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/YuMincho.ttc && \    
    mktexlsr && \
    luaotfload-tool --update --force && \
    fc-cache -r && \
    kanji-config-updmap-sys status && \
    # Set up latexmk and llmk
    tlmgr install \
      latexmk && \
    wget -q -O /usr/local/bin/llmk https://raw.githubusercontent.com/wtsnjp/llmk/master/llmk.lua && \
    chmod +x /usr/local/bin/llmk


VOLUME ["/usr/local/texlive/${TL_VERSION}/texmf-var/luatex-cache"]

WORKDIR /app
CMD ["sh"]
