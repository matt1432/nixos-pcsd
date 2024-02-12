# Dependencies
# - pcs
# - xmldiff script

RESOURCE="$1"

CONFIG_CMD="$2"
CURRENT_CMD=$(pcs resource config "$RESOURCE" --output-format cmd)

sanitized_config=$(echo "$CONFIG_CMD" | sed 's|\(pcs resource create\)|\1 -f /tmp/test1|' | sed 's/--disabled//')
sanitized_current=$(echo "$CURRENT_CMD" | sed 's|\(pcs resource create\)|\1 -f /tmp/test2|' | tr -d '\\\n')

rm -f /tmp/test1 && $sanitized_config
rm -f /tmp/test2 && $sanitized_current

xmldiff /tmp/test1 /tmp/test2

rm -f /tmp/test1 /tmp/test2
