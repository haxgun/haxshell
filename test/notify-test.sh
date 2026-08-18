#!/usr/bin/env sh

INTERVAL=3

# Optional custom image:
#   ./notify-test.sh ~/Pictures/avatar.png
IMAGE="${1:-}"

if ! command -v notify-send >/dev/null 2>&1; then
    echo "Error: notify-send was not found."
    echo "Install the libnotify package."
    exit 1
fi

send() {
    notify-send "$@"
    sleep "$INTERVAL"
}

echo "=== notify-send test loop ==="
echo "Interval: ${INTERVAL}s"
echo "Stop with: Ctrl+C"
echo

while true; do
    # 1. Standard notification
    send \
        --app-name="Test App" \
        --icon="dialog-information" \
        "Standard Notification" \
        "This is a normal informational notification."

    # 2. Low urgency
    send \
        --app-name="Background Service" \
        --urgency=low \
        --icon="emblem-default" \
        "Low Urgency" \
        "A background notification with low priority."

    # 3. Normal urgency
    send \
        --app-name="Telegram" \
        --urgency=normal \
        --icon="telegram" \
        "Telegram" \
        "New message from Alex."

    # 4. Critical urgency
    send \
        --app-name="System Monitor" \
        --urgency=critical \
        --icon="dialog-error" \
        "Critical Notification" \
        "CPU temperature has reached 95°C."

    # 5. Success
    send \
        --app-name="Updater" \
        --icon="emblem-ok-symbolic" \
        "Update Complete" \
        "All packages were updated successfully."

    # 6. Warning
    send \
        --app-name="Battery" \
        --urgency=normal \
        --icon="battery-low" \
        "Low Battery" \
        "15% battery remaining."

    # 7. Error
    send \
        --app-name="Backup" \
        --urgency=critical \
        --icon="dialog-error" \
        "Backup Failed" \
        "Could not connect to the backup server."

    # 8. Wi-Fi / network
    send \
        --app-name="NetworkManager" \
        --icon="network-wireless" \
        "Wi-Fi Connected" \
        "Connected to Home 5GHz."

    # 9. Bluetooth
    send \
        --app-name="Bluetooth" \
        --icon="bluetooth" \
        "Device Connected" \
        "AirPods Pro are now connected."

    # 10. Volume
    send \
        --app-name="Audio" \
        --icon="audio-volume-high" \
        --hint=int:value:75 \
        "Volume" \
        "Volume level: 75%"

    # 11. Progress 10%
    send \
        --app-name="Downloader" \
        --icon="folder-download" \
        --hint=int:value:10 \
        "Downloading File" \
        "10% complete"

    # 12. Progress 50%
    send \
        --app-name="Downloader" \
        --icon="folder-download" \
        --hint=int:value:50 \
        "Downloading File" \
        "50% complete"

    # 13. Progress 90%
    send \
        --app-name="Downloader" \
        --icon="folder-download" \
        --hint=int:value:90 \
        "Downloading File" \
        "90% complete"

    # 14. Music player
    send \
        --app-name="Spotify" \
        --icon="audio-x-generic" \
        "Now Playing" \
        "Daft Punk — Instant Crush"

    # 15. Discord
    send \
        --app-name="Discord" \
        --icon="discord" \
        "Discord" \
        "john: Have you seen the new commit?"

    # 16. Browser
    send \
        --app-name="Firefox" \
        --icon="firefox" \
        "Firefox" \
        "File download completed."

    # 17. Terminal / build
    send \
        --app-name="Terminal" \
        --icon="utilities-terminal" \
        "Build Finished" \
        "Project built successfully in 2.4 seconds."

    # 18. Calendar
    send \
        --app-name="Calendar" \
        --icon="x-office-calendar" \
        "Reminder" \
        "Your meeting starts in 10 minutes."

    # 19. Email
    send \
        --app-name="Mail" \
        --icon="mail-unread" \
        "New Email" \
        "OpenAI — Your monthly invoice is ready"

    # 20. Screenshot
    send \
        --app-name="Screenshot" \
        --icon="camera-photo" \
        "Screenshot Saved" \
        "~/Pictures/Screenshots/screenshot.png"

    # 21. Transient notification
    send \
        --app-name="Clipboard" \
        --icon="edit-copy" \
        --hint=boolean:transient:true \
        "Copied" \
        "Text was copied to the clipboard."

    # 22. Resident notification
    send \
        --app-name="VPN" \
        --icon="network-vpn" \
        --hint=boolean:resident:true \
        "VPN Connected" \
        "KLAR VPN • Germany • 24 ms"

    # 23. Instant messaging category
    send \
        --app-name="Messenger" \
        --icon="mail-message-new" \
        --category="im.received" \
        "New Message" \
        "Hey! How are you?"

    # 24. Email category
    send \
        --app-name="Thunderbird" \
        --icon="mail-unread" \
        --category="email.arrived" \
        "New Email" \
        "A new email has arrived."

    # 25. Device notification
    send \
        --app-name="Devices" \
        --icon="drive-removable-media" \
        --category="device.added" \
        "USB Device Connected" \
        "Kingston DataTraveler is ready to use."

    # 26. Sound hint
    send \
        --app-name="Chat" \
        --icon="mail-message-new" \
        --hint=string:sound-name:message-new-instant \
        "New Message" \
        "This notification requests a system sound."

    # 27. Long body text
    send \
        --app-name="News" \
        --icon="application-rss+xml" \
        "Notification with Long Text" \
        "This is intentionally a very long notification body used to test text wrapping, maximum notification width, line limits, truncation, and the behavior of the notification daemon when displaying large amounts of text."

    # 28. Unicode / emoji
    send \
        --app-name="Messages" \
        --icon="face-smile" \
        "Hello 👋" \
        "Unicode test: 🚀 ❤️ 🔥 Linux → Wayland → Hyprland"

    # 29. Title only
    send \
        --app-name="Minimal" \
        --icon="dialog-information" \
        "Title-only Notification"

    # 30. Custom image from a file
    if [ -n "$IMAGE" ] && [ -f "$IMAGE" ]; then
        send \
            --app-name="Photos" \
            --icon="$IMAGE" \
            "Notification with Image" \
            "Image loaded from file:
$IMAGE"
    fi

done
