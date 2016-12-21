function sendmessage() {
  tgmessage="$1"
  BOTID="$BOT_TOKEN"  #Generated by Telegram's BotFather, used to notify testers groups
  if [ "$2" == "testers" ]; then
  chat_id="$CHAT_ID"  # The ID to the chat where the messages go
  fi
  if [ "$2" == "updates" ]; then
  echo "Gonna get some updates for ya"
  fi
  if [ -z $chat_id ]; then
  echo
  echo "I didn't get a chat_id from your input, or you were confused,"
  echo "so here's a curl of /getUpdates for you to look at!"
  echo
  curl "https://api.telegram.org/bot$BOTID/getUpdates"
  else
  curl "https://api.telegram.org/bot$BOTID/sendmessage" --data "text=$tgmessage&chat_id=$chat_id&parse_mode=Markdown" &>/dev/null
  fi
}

function build-for-jalebi() {
  [ -d build ] || repo sync -c --no-tags build && INITIAL_SYNC=true && unset SYNC
  . build/envsetup.sh
  [ "$INITIAL_SYNC" == "true" ]; reposync
  [ "$SYNC" == "true" ]; reposync turbo
  breakfast "$TARGET_DEVICE"
  repopick "$repopicks"
  lunch "$LUNCH_TARGET"
  [ -z "$CLEAN_BUILD" ]; make clean && ./prebuilts/sdk/tools/jack-admin kill-server
  make bacon -j24
  ./prebuilts/sdk/tools/jack-admin kill-server
  cd "$OUT"
  [ -z "$UPLOAD" ]upload
}

function upload() {
  echo "upload script"
  #filename_orig="XOS_jalebi_7.0_$(date +%Y%m%d).zip"
  filename="XOS_jalebi_7.0_$(date +%Y%m%d).zip" # We use two variables incase we want to tag the file with a word, adjust $filename for using it

  [ -e $filename_orig ] ||  sendmessage "Build failed. FFFFUUUCCCKKK!" "testers"

  mv $filename_orig $filename
  ZIP_SIZE_BYTES=$(stat --printf="%s" $filename)
  echo "zip size $ZIP_SIZE_BYTES"
  ZIP_SIZE_MB=$((ZIP_SIZE_BYTES / 1000000)) # M
  estimated_upload_time=$((ZIP_SIZE_MB / 60 + 1)) # ~0.75mbps
  sendmessage "The build is uploading
  Estimated upload duration: $estimated_upload_time" "testers"
  echo "Uploading the zip $filename"
  rsync -e ssh "$filename" msf-jarvis@frs.sourceforge.net:/home/frs/project/xos-for-jalebi/
  sleep 1
  ret=$?
  sleep 4
  sendmessage "$changelog" "testers"
  exit "$ret"
}

export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
#prebuilts/misc/linux-x86/ccache/ccache -M 30G  # Only needed for the initial build...I think
sendmessage "Build started. This may take up to an hour!
Changelog will come with the build link

To see what's coming in the new build, check this [link](http://review.halogenos.org/#/q/status:open)" "testers"
cd xos
build-for-jalebi