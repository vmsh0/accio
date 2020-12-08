accio(1)

# NAME

accio - Initrd cryptsetup hook to retrieve keys from hardware tokens

# SYNOPSIS

_accio_ help

_accio_ key <volname>

_accio_ enroll <volname> <dev>

_accio_ deroll <volname> <dev>

_accio_ verify

# SUB-COMMANDS

*help*
	Prints an help message with the available commands.

*key*
	Deploys the key for _<volname>_ into */etc/cryptsetup-keys.d*. This is
	the option used for volume activation during startup; it is generally
	not used by the user outside of testing a setup.

*enroll*
	Starts an interactive procedure to enroll _<volname>_ on device
	_<dev>_. This will add the correct key to the volume for activation
	using your hardware token.

*deroll*
	Starts an interactive procedure to de-enroll _<volname>_ on device
	_<dev>_. This will remove the key that was previously added by _enroll_,
	provided that you can activate that key.

*verify*
	Verifies all the configuration files found in */etc/cryptsetup-keys.d*.

# GENERAL CONCEPT

*accio* provides a mechanism for encrypted volume activation using hardware
tokens. It achieves this by hooking into the cryptsetup phase of a standard
systemd boot - see *bootup*(7) -, and deploying the keys for enrolled devices
before their _systemd-cryptsetup@.service_ units get activated.

*accio* doesn't currently delete the keys after device activation. This
feature is planned for a future version. For now, you should use the
systemd-cryptsetup-generator *keyfile-erase* flag, by specifying it either in
_/etc/crypttab.initrd_ or in the kernel command line, depending on your setup
(which is just as secure). See *crypttab*(5).

# QUICK SETUP FOR ARCH LINUX AND YUBIKEY 5 NFC

Assuming that you're running Arch Linux (with a systemd boot) and a Yubikey 5
NFC, setting up *accio* is very easy.

## Setting up the YubiKey

First, set up your YubiKey with a slot for HMAC-SHA1 challenge-response. You
can do this using *yubikey-personalization-gui*, or from the command line:
	ykpersonalize -2 -ochal-resp -ochal-hmac -ohmac-lt64

The above command will set up slot two for HMAC-SHA1 challenge-response mode.
If you want to require a button press on your YubiKey for the response to be
sent, you should add the _-ochal-btn-trig_ flag.

## Writing a configuration file

Find out what your crypt volume is called and on which device it lives with the
	lsblk
command. You should see a *crypt* device with a *part* parent. The former is
your _<volname>_, while the latter is your _<dev>_.

Create an *accio* file for your volume with the *challenge* and *slot* options:
	echo "challenge=file" | sudo tee /etc/cryptsetup-keys.d/<volname>.accio
	echo "slot=2" | sudo tee /etc/cryptsetup-keys.d/<volname>.accio

In this example we are using slot 2, as well as a challenge file, so let's
create that file as well:
	sudo dd if=/dev/random of=/etc/cryptsetup-keys.d/<volname>.challenge
	bs=64 count=1

## Enrolling the volume

Issue the following command as root:
	accio enroll <volname> <dev>

Follow the interactive procedure.

## Adding the hook to initrd

Edit the _/etc/mkinitcpio.conf_ file with your favourite editor, adding
*sd-fluffy* to the _HOOKS_ array. The position is irrelevant (I like to add it
near the *sd-encrypt* hook.)

Give the following command to generate a fresh initrd:
	mkinitcpio -P

## Configuring systemd-cryptsetup-generator to shred the keys

Add the *keyfile-erase* flag to your crypt device, either in the kernel command
line (bootloader configuration) or in /etc/cryptsetup.initrd.

If you installed Arch Linux with full disk encryption following the tutorial on
the Wiki, you probably wish to do the former. This is very easy. Just open the
file containing the bootloader entry for Arch Linux. You should have a command
line parameter similar to the following:
	rd.luks.name=<uuid>=<volname>

Add the following parameter next to it:
	rd.luks.options=<uuid>=keyfile-erase

If you need to do the latter, just append the *keyfile-erase* flag to the
*options* (4th) column in _/etc/crypttab.initrd_.

*accio* deploys the keys to _/run/cryptsetup-keys.d_, which is discarded at the
end of the boot process before the _/init_ process is started. However, this
leaves the key in RAM indefinitely and thus should be avoided. The
*keyfile-erase* option securely shreds the file after device activation, thus
avoiding the issue.

# CONFIGURATION

To enable *accio* for an ecrypted volume, you have to add an appropriate
configuration file to _/etc/cryptsetup-keys.d_.

*accio* configuration files have the ".accio" extension. They are simple
key-value stores which use the following format:
	key=value

The available parameters are:

[[ *Key*
:[ *Value*
|  *challenge*
:  The challenge for challenge-response tokens
|  *slot*
:  The token slot to use


*challenge*
	For challenge-response tokens, this configuration options allows to
	specify the challenge data used to query the hardware token for the
	key. Available values are:
	- *ascii:<any ascii string>*: use the specified ascii string as the
	  challenge
	- *file*: read the challenge (as a raw byte stream) from the file
	  called <devname>.challenge in _/etc/cryptsetup-keys.d_
	- *query*: query the user to insert the challenge using a keyboard
	  at activation time

	Note that the *query* option effectively adds an authentication
	factor, making the setup more secure.

*slot*
	Specifies which slot is used for devices such as YubiKeys.

# ACTIVATE AT BOOT

*accio* needs to be integrated in your initrd in order to activate encrypted
volumes.

For Arch Linux systems (or other systems based on mkinitcpio), you simply need
to activate the provided *sd-accio* hook. To do that, add "sd-accio" to the
_HOOKS_ section of _/etc/mkinitcpio.conf_. Position is not important, but you
may want to put it near "sd-encrypt" for the sake of organization. After doing
this, refresh your initcpio images with:
	mkinitcpio -P

(If you manually installed *accio* from sources, remember to copy _sd-accio_ to
_/usr/lib/initcpio/install_. If you installed from a package, you're already
set.)

For other systems, please inspect the _sd-accio_ file to find out which files
to add to your inird, and do so according to your setup.

# COMPATIBLE DEVICES

*accio* is currently only tested with the YubiKey 5 NFC token. It should
support any other Yubico device supporting HMAC-SHA1 the challenge-respose
without any modifications.

If you are interested in support for more devices, please consider sending a
patch or the device itself to me. I make no promises, but I'm generally
interested in adding more support. See the *AUTHORS* section for contact
information.

# NON-SYSTEMD BOOT SUPPORT

*accio* only supports systemd-based initrd environments. I'm generally not
interested in supporting anything else. You can probably very easily set up
*accio* in your system in such a way that your existing initrd setup can
use the deployed keys. If you succeed, and the needed modifications to *accio*
are minimal, please send me a patch!

# LOGGING

*accio* outputs log messages to stdout and stderr. These are inserted in the
journal and can be reviewed after boot with
	journalctl -b -g accio

# SEE ALSO

*bootup*(7) *crypttab*(5) *systemd-cryptsetup-generator*(8) *ykpersonalize*(1)

# AUTHORS

Written and maintained by Riccardo Paolo Bestetti <pbl@bestov.io>.

Webpage: https://www.bestov.io/software/accio

Please refer to the webpage for bug reports. You can write me an email for
patches, suggestions, and feature requests. Thanks for using my software!

