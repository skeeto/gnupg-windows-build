FROM debian:buster-slim

ARG GNUPG_VERSION=2.2.25
ARG ICONV_VERSION=1.16
ARG LIBASSUAN_VERSION=2.5.4
ARG LIBGCRYPT_VERSION=1.8.7
ARG LIBGPGERROR_VERSION=1.39
ARG LIBKSBA_VERSION=1.4.0
ARG NPTH_VERSION=1.6
ARG PINENTRY_VERSION=1.1.0

ARG PREFIX=/gnupg-$GNUPG_VERSION-x86_64

RUN apt-get update && apt-get install --yes --no-install-recommends \
        build-essential curl gcc-mingw-w64-x86-64 gettext zip

# Download, verify, and unpack

RUN curl --insecure --location --remote-name-all \
    https://gnupg.org/ftp/gcrypt/gnupg/gnupg-$GNUPG_VERSION.tar.bz2 \
    https://gnupg.org/ftp/gcrypt/libassuan/libassuan-$LIBASSUAN_VERSION.tar.bz2 \
    https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-$LIBGCRYPT_VERSION.tar.bz2 \
    https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-$LIBGPGERROR_VERSION.tar.bz2 \
    https://gnupg.org/ftp/gcrypt/libksba/libksba-$LIBKSBA_VERSION.tar.bz2 \
    https://gnupg.org/ftp/gcrypt/npth/npth-$NPTH_VERSION.tar.bz2 \
    https://gnupg.org/ftp/gcrypt/pinentry/pinentry-$PINENTRY_VERSION.tar.bz2 \
    https://ftp.gnu.org/gnu/libiconv/libiconv-$ICONV_VERSION.tar.gz
COPY SHA256SUMS .
RUN sha256sum -c SHA256SUMS && \
    tar xjf gnupg-$GNUPG_VERSION.tar.bz2 && \
    tar xzf libiconv-$ICONV_VERSION.tar.gz && \
    tar xjf libassuan-$LIBASSUAN_VERSION.tar.bz2 && \
    tar xjf libgcrypt-$LIBGCRYPT_VERSION.tar.bz2 && \
    tar xjf libgpg-error-$LIBGPGERROR_VERSION.tar.bz2 && \
    tar xjf libksba-$LIBKSBA_VERSION.tar.bz2 && \
    tar xjf npth-$NPTH_VERSION.tar.bz2 && \
    tar xjf pinentry-$PINENTRY_VERSION.tar.bz2

WORKDIR /pth
RUN /npth-$NPTH_VERSION/configure \
        --host=x86_64-w64-mingw32 \
        --prefix="/deps" \
        --enable-shared=no \
        --enable-static=yes \
        CFLAGS="-Os"
RUN make -j$(nproc)
RUN make install

WORKDIR /libgpg-error
RUN /libgpg-error-$LIBGPGERROR_VERSION/configure \
        --host=x86_64-w64-mingw32 \
        --prefix="/deps" \
        --enable-shared=no \
        --enable-static=yes \
        --disable-nls \
        --disable-doc \
        --disable-languages \
        CFLAGS="-Os"
RUN make -j$(nproc)
RUN make install

WORKDIR /libassuan
RUN /libassuan-$LIBASSUAN_VERSION/configure \
        --host=x86_64-w64-mingw32 \
        --prefix="/deps" \
        --enable-shared=no \
        --enable-static=yes \
        --with-libgpg-error-prefix="/deps" \
        CFLAGS="-Os"
RUN make -j$(nproc)
RUN make install

WORKDIR /libgcrypt
RUN /libgcrypt-$LIBGCRYPT_VERSION/configure \
        --host=x86_64-w64-mingw32 \
        --prefix="/deps" \
        --enable-shared=no \
        --enable-static=yes \
        --disable-doc \
        --with-libgpg-error-prefix="/deps" \
        CFLAGS="-Os"
RUN make -j$(nproc)
RUN make install

WORKDIR /libksba
RUN /libksba-$LIBKSBA_VERSION/configure \
        --host=x86_64-w64-mingw32 \
        --prefix="/deps" \
        --enable-shared=no \
        --enable-static=yes \
        --with-libgpg-error-prefix="/deps"
RUN make -j$(nproc)
RUN make install

WORKDIR /gnupg
RUN /gnupg-$GNUPG_VERSION/configure \
        --host=x86_64-w64-mingw32 \
        --prefix="$PREFIX" \
        --with-npth-prefix="/deps" \
        --with-libgpg-error-prefix="/deps" \
        --with-libgcrypt-prefix="/deps" \
        --with-libassuan-prefix="/deps" \
        --with-ksba-prefix="/deps" \
        --disable-bzip2 \
        --disable-card-support \
        --disable-ccid-driver \
        --disable-dirmngr \
        --disable-doc \
        --disable-gnutls \
        --disable-gpg-blowfish \
        --disable-gpg-cast5 \
        --disable-gpg-idea \
        --disable-gpg-md5 \
        --disable-gpg-rmd160 \
        --disable-gpgtar \
        --disable-ldap \
        --disable-libdns \
        --disable-nls \
        --disable-ntbtls \
        --disable-photo-viewers \
        --disable-regex \
        --disable-scdaemon \
        --disable-sqlite \
        --disable-wks-tools \
        --disable-zip \
        CFLAGS="-Os -fcommon" \
        LDFLAGS="-static -s" \
        LIBS="-lws2_32"
RUN make -j$(nproc)
RUN make install

WORKDIR /iconv
RUN /libiconv-$ICONV_VERSION/configure \
        --host=x86_64-w64-mingw32 \
        --prefix="/deps" \
        --enable-shared=no \
        --enable-static=yes \
        --disable-nls \
        --disable-dependency-tracking \
        CFLAGS="-Os"
RUN make -j$(nproc)
RUN make install

WORKDIR /pinentry
RUN /pinentry-$PINENTRY_VERSION/configure \
        --host=x86_64-w64-mingw32 \
        --prefix="$PREFIX" \
        --with-libgpg-error-prefix="/deps" \
        --with-libassuan-prefix="/deps" \
        --with-libiconv-prefix="/deps" \
        --disable-ncurses \
        --disable-libsecret \
        --disable-pinentry-tty \
        --disable-pinentry-curses \
        --disable-pinentry-emacs \
        --disable-inside-emacs \
        --disable-pinentry-gtk2 \
        --disable-pinentry-gnome3 \
        --disable-pinentry-qt \
        --disable-pinentry-tqt \
        --disable-pinentry-fltk \
        LDFLAGS="-static -s" \
        LIBS="-lws2_32"
RUN make -j$(nproc)
RUN cp w32/pinentry-w32.exe $PREFIX/bin/pinentry.exe

WORKDIR /
ENV PREFIX=${PREFIX}
CMD zip -qXr - $PREFIX
