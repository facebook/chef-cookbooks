#!/bin/bash
#
# To use this filter with less, define LESSOPEN:
# export LESSOPEN="|/usr/bin/lesspipe.sh %s"
#
# The script should return zero if the output was valid and non-zero
# otherwise, so less could detect even a valid empty output
# (for example while uncompressing gzipped empty file).
# For backward-compatibility, this is not required by default. To turn
# this functionality there should be another vertical bar (|) straight
# after the first one in the LESSOPEN environment variable:
# export LESSOPEN="||/usr/bin/lesspipe.sh %s"

if [ ! -e "$1" ] ; then
	exit 1
fi

if [ -d "$1" ] ; then
	ls -alF -- "$1"
	exit $?
fi

exec 2>/dev/null

# Allow for user defined filters
if [ -x ~/.lessfilter ]; then
	if ~/.lessfilter "$1"; then
		exit 0
	fi
fi

manfilter ()
{
	if test -x /usr/bin/man ; then
		# See rhbz#1241543 for more info.  Well, actually we firstly
		# used 'man -l', then we switched to groff, and then we again
		# switched back to 'man -l'.
		/usr/bin/man -P /usr/bin/cat -l "$1"
	elif test -x /usr/bin/groff; then
		# This is from pre-rhbz#1241543-time.
		groff -Tascii -mandoc "$1" | cat -s
	else
		echo "WARNING:"
		echo "WARNING: to better show manual pages, install 'man-db' package"
		echo "WARNING:"
		cat "$1"
	fi
}

export MAN_KEEP_FORMATTING=1

case "$1" in
*.[1-9n].bz2|*.[1-9]x.bz2|*.man.bz2|*.[1-9n].[gx]z|*.[1-9]x.[gx]z|*.man.[gx]z|*.[1-9n].lzma|*.[1-9]x.lzma|*.man.lzma|*.[1-9n].zst|*.[1-9]x.zst|*.man.zst)
	case "$1" in
	*.gz)		DECOMPRESSOR="gzip -dc" ;;
	*.bz2)		DECOMPRESSOR="bzip2 -dc" ;;
	*.xz|*.lzma)	DECOMPRESSOR="xz -dc" ;;
	*.zst)		DECOMPRESSOR="zstd -dcq" ;;
	esac
	if [ -n "$DECOMPRESSOR" ] && $DECOMPRESSOR -- "$1" | file - | grep -q troff; then
		$DECOMPRESSOR -- "$1" | manfilter -
		exit $?
	fi ;;&
*.[1-9n]|*.[1-9]x|*.man)
	if file "$1" | grep -q troff; then
		manfilter "$1"
		exit $?
	fi ;;&
*.tar) tar tvvf "$1"; exit $? ;;
*.tgz|*.tar.gz|*.tar.[zZ]) tar tzvvf "$1"; exit $? ;;
*.tar.xz) tar Jtvvf "$1"; exit $? ;;
*.tzst|*.tar.zst) tar -I zstd tvvf "$1"; exit $? ;;
*.xz|*.lzma) xz -dc -- "$1"; exit $? ;;
*.tar.bz2|*.tbz2) bzip2 -dc -- "$1" | tar tvvf -; exit $? ;;
*.[zZ]|*.gz) gzip -dc -- "$1"; exit $? ;;
*.bz2) bzip2 -dc -- "$1"; exit $? ;;
*.zst) zstd -dcq -- "$1"; exit $? ;;
*.zip|*.jar|*.nbm) zipinfo -- "$1"; exit $? ;;
# --nomanifest -> rhbz#1450277
*.rpm) rpm -qpivl --changelog --nomanifest -- "$1"; exit $? ;;
*.cpi|*.cpio) cpio -itv < "$1"; exit $? ;;
*.gpg)
	if [ -x /usr/bin/gpg2 ]; then
		gpg2 -d "$1"
		exit $?
	elif [ -x /usr/bin/gpg ]; then
		gpg -d "$1"
		exit $?
	else
		echo "No GnuPG available."
		echo "Install gnupg2 or gnupg to show encrypted files."
		exit 1
	fi ;;
*.gif|*.jpeg|*.jpg|*.pcd|*.png|*.tga|*.tiff|*.tif)
	if [ -x /usr/bin/identify ]; then
		identify "$1"
		exit $?
	elif [ -x /usr/bin/gm ]; then
		gm identify "$1"
		exit $?
	else
		echo "No identify available"
		echo "Install ImageMagick or GraphicsMagick to browse images"
		exit 1
	fi ;;
*)
	if [ -x /usr/bin/file ] && [ -x /usr/bin/iconv ] && [ -x /usr/bin/cut ]; then
    case $(file -b "$1") in
		*UTF-16*) conv='UTF-16' ;;
		*UTF-32*) conv='UTF-32' ;;
		esac
		if [ -n "$conv" ]; then
      env=$(echo "$LANG" | cut -d. -f2)
			if [ -n "$env" ] && [ "$conv" != "$env" ]; then
				iconv -f "$conv" -t "$env" "$1"
				exit $?
			fi
		fi
	fi
	exit 1
esac
