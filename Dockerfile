FROM ubuntu:21.04

LABEL maintainer="koba1014@gmail.com"

ENV TL_VERSION=2021
ENV TL_PATH         /usr/local/texlive
ENV PATH            ${TL_PATH}/bin/x86_64-linux:/bin:${PATH}

WORKDIR /tmp

# Install required packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    # Basic tools
    wget unzip ghostscript \
    # for tlmgr
    perl-modules-5.28 \
    # for XeTeX
    fontconfig && \
    # Clean caches
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# Install TeX Live
RUN mkdir install-tl-unx && \
    wget -qO- http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | \
      tar -xz -C ./install-tl-unx --strip-components=1 && \
    printf "%s\n" \
      "TEXDIR ${TL_PATH}" \
      "selected_scheme scheme-full" \
      "option_doc 0" \
      "option_src 0" \
      > ./install-tl-unx/texlive.profile && \
    ./install-tl-unx/install-tl \
      -profile ./install-tl-unx/texlive.profile && \
    rm -rf *

# Set up Japanese fonts
RUN tlmgr install \
      collection-latexextra \
      collection-fontsrecommended \
      collection-langjapanese \
      latexmk

# Install llmk
RUN wget -q -O /usr/local/bin/llmk https://raw.githubusercontent.com/wtsnjp/llmk/master/llmk.lua && \
      chmod +x /usr/local/bin/llmk

# Set up hiragino font map
RUN tlmgr repository add http://contrib.texlive.info/current tlcontrib
RUN tlmgr pinning add tlcontrib '*'
RUN tlmgr update --self
RUN tlmgr install \
   japanese-otf-nonfree \
   japanese-otf-uptex-nonfree \
   ptex-fontmaps-macos \
   cjk-gs-integrate-macos
RUN cjk-gs-integrate-macos --cleanup --force
RUN cjk-gs-integrate-macos --link-texmf --force \
  --fontdef-add=$(kpsewhich -var-value=TEXMFDIST)/fonts/misc/cjk-gs-integrate-macos/cjkgs-macos-highsierra.dat
RUN kanji-config-updmap-sys --jis2004 hiragino-highsierra-pron
RUN luaotfload-tool -u -f
RUN fc-cache -r

# Set default LANG=ja_JP.UTF-8. Without locale settings hiragino fonts cannot be found. Its file name is Japanese.
RUN apt-get update && \
    apt-get install -y locales && \
    # Clean caches
    apt-get autoremove -y && \
    apt-get clean
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "ja_JP.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    /usr/sbin/update-locale LANG=ja_JP.UTF-8
ENV lang=ja_JP.UTF-8

# Set up hiragino fonts link.
WORKDIR /usr/share/fonts/SystemLibraryFonts
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ明朝 ProN.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSerif.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ丸ゴ ProN W4.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSansR-W4.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W3.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W3.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W6.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W6.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W8.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W8.ttc
RUN mktexlsr


VOLUME ["/usr/local/texlive/${TL_VERSION}/texmf-var/luatex-cache"]
WORKDIR /workdir

CMD ["bash"]
