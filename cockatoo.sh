#!/bin/bash

# Application List
applicationList=(
    '{"shortcode": "arc", "appName": "Arc Browser", "appPath": "/Applications/Arc.app", "iconPath": "/Applications/Arc.app/Contents/Resources/AppIcon.icns", "bundleId": "company.thebrowser.Browser"}'
    '{"shortcode": "brave", "appName": "Brave Browser", "appPath": "/Applications/Brave Browser.app", "iconPath": "/Applications/Brave Browser.app/Contents/Resources/app.icns", "bundleId": "com.brave.Browser"}'
    '{"shortcode": "canary", "appName": "Canary", "appPath": "/Applications/Canary.app", "iconPath": "/Applications/Canary.app/Contents/Resources/CanaryLogo.icns", "bundleId": "com.obvious-fail.canary"}'
    '{"shortcode": "chrome", "appName": "Google Chrome", "appPath": "/Applications/Google Chrome.app", "iconPath": "/Applications/Google Chrome.app/Contents/Resources/app.icns", "bundleId": "com.google.Chrome"}'
    '{"shortcode": "displaylink", "appName": "DisplayLink Manager", "appPath": "/Applications/DisplayLink Manager.app", "iconPath": "/Applications/DisplayLink Manager.app/Contents/Resources/Icon.icns", "bundleId": "com.displaylink.DisplayLinkUserAgent"}'
    '{"shortcode": "edge", "appName": "Microsoft Edge", "appPath": "/Applications/Microsoft Edge.app", "iconPath": "/Applications/Microsoft Edge.app/Contents/Resources/AppIcon.icns", "bundleId": "/Applications/Microsoft Edge.app"}'
    '{"shortcode": "firefox", "appName": "Mozilla Firefox", "appPath": "/Applications/Firefox.app", "iconPath": "/Applications/Firefox.app/Contents/Resources/firefox.icns", "bundleId": "org.mozilla.firefox"}'
    '{"shortcode": "kap", "appName": "Kap", "appPath": "/Applications/Kap.app", "iconPath": "/Applications/Kap.app/Contents/Resources/icon.icns", "bundleId": "com.wulkano.kap"}'
    '{"shortcode": "obs", "appName": "OBS Studio", "appPath": "/Applications/OBS.app", "iconPath": "/Applications/OBS.app/Contents/Resources/AppIcon.icns", "bundleId": "com.obsproject.obs-studio"}'
    '{"shortcode": "slack", "appName": "Slack", "appPath": "/Applications/Slack.app", "iconPath": "/Applications/Slack.app/Contents/Resources/slack-key.icns", "bundleId": "com.tinyspeck.slackmacgap"}'
    '{"shortcode": "teams", "appName": "Microsoft Teams", "appPath": "/Applications/Microsoft Teams.app", "iconPath": "/Applications/Microsoft Teams.app/Contents/Resources/icon+new.icns", "bundleId": "com.microsoft.teams2"}'
    '{"shortcode": "webex", "appName": "Cisco Webex", "appPath": "/Applications/Webex.app", "iconPath": "/Applications/Webex.app/Contents/Resources/app_publishing_logo.icns", "bundleId": "Cisco-Systems.Spark"}'
    '{"shortcode": "zoom", "appName": "Zoom", "appPath": "/Applications/zoom.us.app", "iconPath": "/Applications/zoom.us.app/Contents/Resources/ZPLogo.icns", "bundleId": "us.zoom.xos"}'
)

runAsUser() {
  # From https://scriptingosx.com/2020/08/running-a-command-as-another-user
  if [ "$currentUser" != "loginwindow" ]; then
    launchctl asuser "$uid" sudo -u "$currentUser" "$@"
  else
    echo "No user logged in"
    # Uncomment the exit command to make the function exit with an error when no user is logged in
    # exit 1
  fi
}

# Look up each application path to see if it exists on machine, if it does, print "true" else "false"
for app in "${applicationList[@]}"; do
    shortcode=$(echo "$app" | jq -r '.shortcode')
    appName=$(echo "$app" | jq -r '.appName')
    appPath=$(echo "$app" | jq -r '.appPath')
    iconPath=$(echo "$app" | jq -r '.iconPath')
    bundleId=$(echo "$app" | jq -r '.bundleId')

    if [ -d "$appPath" ]; then
        echo "✅ $appName is installed"
        installedapps+=("$shortcode")
    else
        echo "❌ $appName is not installed"
    fi

done

echo ""
echo "Installed Apps: ${installedApps[@]}"
echo ""

for referenceShortCode in "${installedapps[@]}"; do
    for referenceApp in "${applicationList[@]}"; do
        if [[ $(echo "$referenceApp" | jq -r '.shortcode') == "$referenceShortCode" ]]; then
            bundleID=$(echo "$referenceApp" | jq -r '.bundleId')
            # echo "Looking up bundle ID: $bundleID for $referenceShortCode"
            ApprovalCheck=$(sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" 'SELECT client FROM access WHERE service like "kTCCServiceScreenCapture" AND auth_value = "2"' | grep -o "$bundleID")
            if [ -z "$ApprovalCheck" ]; then
                echo "❌ $bundleID is missing from the TCC database"
                MissingPermissions+=("$referenceShortCode")
            else
                echo "✅ $ApprovalCheck has permission to screen capture"
            fi
        fi
    done
done

echo MissingPermissions: ${MissingPermissions[@]}

for shortcode in "${MissingPermissions[@]}"; do
    for app in "${applicationList[@]}"; do
        if [[ $(echo "$app" | jq -r '.shortcode') == "$shortcode" ]]; then
            appName=$(echo "$app" | jq -r '.appName')
            iconPath=$(echo "$app" | jq -r '.iconPath')
            ArgsList+=( --listitem "$appName,icon=$iconPath")
        fi
    done
done

# Remember to add back runAsUser Mike ;)
/usr/local/bin/dialog --title "Screen Sharing Permissions" --message "These applications are currently missing screen sharing permissions, these are essential should you wish to share your screen in a meeting or for a recording." "${ArgsList[@]}" --icon "https://raw.githubusercontent.com/BiosPlus/Cockatoo/main/data/mysteryicon.png" --button1text "Open Preferences" --button2text "Dismiss"