mkdir -p /etc/ccn
[ -e /etc/ccn/servers ] || cp manage/etc/ccn/servers /etc/ccn/servers

(cd manage/usr/bin;         \
  for f in ccnq2*; do        \
    cp $f /usr/bin/$f;      \
    chmod +x /usr/bin/$f;   \
  done )

