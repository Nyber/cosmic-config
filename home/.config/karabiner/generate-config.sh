#!/bin/bash
# Generates karabiner.json from a simple key list.
# All keys get the same rule: fn+key → cmd+option+key (for AeroSpace).
# Run this script after editing the KEYS array, then restart Karabiner.

KEYS=(
    # Arrows (focus/move)
    left_arrow right_arrow up_arrow down_arrow
    # Workspaces
    1 2 3 4 5 6 7 8 9
    # Layout
    slash comma f m q equal_sign hyphen
    # Quick switch
    tab
    # App launchers
    b o s t z
    # Service mode
    semicolon
    # hjkl (service mode join-with)
    h j k l
)

OUTPUT="$HOME/.config/karabiner/karabiner.json"

manipulators=""
for key in "${KEYS[@]}"; do
    [ -n "$manipulators" ] && manipulators+=","
    manipulators+="
                            {
                                \"from\": {
                                    \"key_code\": \"$key\",
                                    \"modifiers\": {
                                        \"mandatory\": [\"fn\"],
                                        \"optional\": [\"any\"]
                                    }
                                },
                                \"to\": [
                                    {
                                        \"key_code\": \"$key\",
                                        \"modifiers\": [\"left_command\", \"left_option\"]
                                    }
                                ],
                                \"type\": \"basic\"
                            }"
done

cat > "$OUTPUT" << EOF
{
    "global": { "show_in_menu_bar": false },
    "profiles": [
        {
            "complex_modifications": {
                "rules": [
                    {
                        "description": "Map fn+key to cmd+option+key for AeroSpace",
                        "manipulators": [$manipulators
                        ]
                    }
                ]
            },
            "name": "Default profile",
            "selected": true,
            "virtual_hid_keyboard": { "keyboard_type_v2": "ansi" }
        }
    ]
}
EOF

echo "Generated $OUTPUT with ${#KEYS[@]} key mappings."
