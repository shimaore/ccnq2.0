mkdir -p /etc/ccn
[ -e /etc/ccn/servers ] || cp manage/etc/ccn/servers /etc/ccn/servers

(cd manage/usr/sbin;         \
  for f in ccnq2*; do        \
    cp $f /usr/sbin/$f;      \
    chmod +x /usr/sbin/$f;   \
  done )

