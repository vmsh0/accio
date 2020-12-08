# Accio
**Initrd cryptsetup hook to retrieve keys from hardware tokens**

Accio is a very small software package which helps you setting up luks volume activation using hardware tokens such as YubiKeys.

Accio is currently in a proto-implementation phase: it is currently written in Bash and only works with a subset of YubiKey tokens (those which support the HMAC-SHA1 challenge-response application).

Although it works, it will not be released as a software package (except on the AUR) until, at the very least, the following gets done:
- Full rewrite in C
- Shell autocompletions
- Better `man` documentation
- Support for identifying tokens
- Architecture supporting multiple token types

## General concept
Accio allows to use an hardware token to unlock a luks volume, instead of having to type in a passphrase.

Booting with Accio requires no user interaction if the token is already plugged in. This allows e.g. to keep a token plugged into your docking station at work or at home to boot without requiring any user intervention.

Accio also supports two-factor authentication, where you have to provide a challange to the hardware token to get the activation key.

Finally, when using Accio, you always retain the ability to fall back to inserting a passphrase, as systemd will ask for one should Accio fail to provide a key. Of course, should you want to disallow using a key, you could remove it from the luks header after enabling Accio, but I highly suggest not doing that, as a lost or broken hardware token will mean loosing all of your data.

## Install

As of now, the only supported platform is Arch Linux. Install the `accio-git` package from the AUR, and refer to the **accio**(1) manpage for a quick tutorial.