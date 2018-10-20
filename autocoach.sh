#!/bin/bash

#adb ${DEVICE_OPTS} shell svc power stayon true
#while true; do ./autocoach.sh 7EX0217A30000909; done

#load parameters
. emu-Nexus5-01-game2.cfg
echo "DEVICE_RESOLUTION=$DEVICE_RESOLUTION"

function exec_timeout()
# $1 = min timeout milliseconds
# $2... = command + arguments
{
    START=$(( $(date +%s%N) / 1000000 ))
    TIMEOUT=$1
    DELTA=0
    shift;

    #execute command    
    $@

    while [ $DELTA -le $TIMEOUT ]; do 
      END=$(( $(date +%s%N) / 1000000 ))
      DELTA=$(( $END - $START ))
    done
    
}

function log {
	echo "`date '+%Y-%m-%d %H:%M:%S'` $1"
}

function resetApp {
	
	if [ "${EMULATED_DEVICE}" = "true" ]; then
		~/Android/Sdk/emulator/emulator @${DEVICE_NAME} -no-audio -no-snapshot -no-window -port $EMULATOR_PORT &
#		~/Android/Sdk/emulator/emulator @${DEVICE_NAME} -no-audio -no-snapshot -port $EMULATOR_PORT &
		EMULATOR_PID=$!
		log "Waiting for the emulator to start..."
		sleep 20
	fi

	log "Restarting the application..."
	log "chiudo app"
	exec_timeout 15000 adb ${DEVICE_OPTS} shell am force-stop com.axa.pocketcoach.prod
	#sleep 15

	log "avvio"
	exec_timeout 16000 adb ${DEVICE_OPTS} shell am start com.axa.pocketcoach.prod/com.teachonmars.lom.SplashActivity
	#sleep 8

	log "swipe per trovare corso"
	#adb ${DEVICE_OPTS} exec-out screencap -p > before-swipe.png
	exec_timeout 4000 adb ${DEVICE_OPTS} shell input swipe ${SWIPE_CORSO}
	#adb ${DEVICE_OPTS} exec-out screencap -p > after-swipe.png
	#sleep 3

	log "tap corso"
	exec_timeout 2000 adb ${DEVICE_OPTS} shell input tap ${TAP_CORSO}
	#sleep 2

	log "swipe sfida"
	#adb ${DEVICE_OPTS} exec-out screencap -p > before-swipe.png
	exec_timeout 4000 adb ${DEVICE_OPTS} shell input swipe ${SWIPE_SFIDA}
	#adb ${DEVICE_OPTS} exec-out screencap -p > after-swipe.png
	#sleep 3

	log "tap sfida"
	adb ${DEVICE_OPTS} exec-out screencap -p > "`date '+%Y-%m-%d_%H.%M.%S'`-debug-screenshot.png"
	exec_timeout 3000 adb ${DEVICE_OPTS} shell input tap ${TAP_SFIDA}
	adb ${DEVICE_OPTS} exec-out screencap -p > "`date '+%Y-%m-%d_%H.%M.%S'`-debug-screenshot.png"
	#sleep 2

	log "tap avversario casuale"
	adb ${DEVICE_OPTS} exec-out screencap -p > "`date '+%Y-%m-%d_%H.%M.%S'`-debug-screenshot.png"
	exec_timeout 5000 adb ${DEVICE_OPTS} shell input tap ${TAP_AVVERSARIO_CASUALE}
	adb ${DEVICE_OPTS} exec-out screencap -p > "`date '+%Y-%m-%d_%H.%M.%S'`-debug-screenshot.png"
	#sleep 3

	log "tap si"
	adb ${DEVICE_OPTS} exec-out screencap -p > "`date '+%Y-%m-%d_%H.%M.%S'`-debug-screenshot.png"
	exec_timeout 4300 adb ${DEVICE_OPTS} shell input tap ${TAP_INIZIA_SFIDA_SI}
	adb ${DEVICE_OPTS} exec-out screencap -p > "`date '+%Y-%m-%d_%H.%M.%S'`-debug-screenshot.png"
	#sleep 4.3
}

################ BEGIN

if [ "$1" != "" ]; then
        log "Parametro: $1"
		DEVICE_OPTS="-s $1"
else
	if [ "${EMULATED_DEVICE}" = "true" ]; then
		DEVICE_OPTS="-s emulator-${EMULATOR_PORT}"
	else
        log "Nessun parametro"
		DEVICE_OPTS=""
	fi
fi
log "DEVICE_OPTS=$DEVICE_OPTS"

resetApp

while true; do

  adb ${DEVICE_OPTS} exec-out screencap -p > screenshot.png && convert screenshot.png -crop "${CROP_OPTIONS}" question.png
  
  #150,1800 --> se è blu è finito il gioco
  TEST=$(convert screenshot.png -format '%[pixel:p{'${TEST_PIXEL_END_GAME}'}]' info:-)
  log $TEST
  if [ "${TEST}" = "${TEST_PIXEL_END_GAME_EXPECTED_VALUE}" ]; then
  	log "fine gioco"
  	exec_timeout 3000 adb ${DEVICE_OPTS} shell input tap ${TAP_FINE_DUELLO_CONTINUA}
  	#sleep 3
    
  	exec_timeout 4000 adb ${DEVICE_OPTS} shell input tap ${TAP_FINE_DUELLO_MESSAGGIO_CONTINUA}
  	#sleep 4
  
  	#avversario casuale
  	exec_timeout 5000 adb ${DEVICE_OPTS} shell input tap ${TAP_AVVERSARIO_CASUALE}
  	#sleep 5

  	exec_timeout 4500 adb ${DEVICE_OPTS} shell input tap ${TAP_INIZIA_SFIDA_SI}
  	#sleep 4.3

  	adb ${DEVICE_OPTS} exec-out screencap -p > screenshot.png && convert screenshot.png -crop "${CROP_OPTIONS}" question.png
  fi
  
  COORD="none"
  
  #controllo se ho già incontrato questa domanda
  QUESTION_HASH=$(convert question.png bmp:- | sha1sum)
  if [ -f "kb/question-${QUESTION_HASH}.txt" ]; then
  	COORD=$(cat "kb/question-${QUESTION_HASH}.txt")
  	log "Domanda già incontrata. Coordinate risposta esatta: ${COORD}"
  fi
  
  if [ "${COORD}" = "none" ]; then
  	#non conosco la domanda, provo la prima
  	log "Domanda nuova, clicco la prima risposta..."
  	Y=$(echo ${PIXEL_CORNER_ANSWER_1} | cut -d\, -f2)
  	log "adb ${DEVICE_OPTS} shell input tap ${X_CENTER_ANSWER} ${Y}"
  	
  	exec_timeout 300 adb ${DEVICE_OPTS} shell input tap ${X_CENTER_ANSWER} ${Y}
  	#sleep 0.3

  	exec_timeout 1500 adb ${DEVICE_OPTS} exec-out screencap -p > try.png
  	#adb ${DEVICE_OPTS} shell "screencap -p > /sdcard/screenshot.png" && adb ${DEVICE_OPTS} pull /sdcard/screenshot.png try.png
  	#sleep 1.5
  	
  	#cerco il box verde
  	#TODO: alla fine il verde dura di piu
	FOUND="KO"
  	for Y in ${PIXEL_CORNER_ANSWER_1_Y} ${PIXEL_CORNER_ANSWER_2_Y} ${PIXEL_CORNER_ANSWER_3_Y} ${PIXEL_CORNER_ANSWER_4_Y}; do 
  		log "cerco il verde alla coordinata: $Y"
  		# uso una domanda qualsiasi come coordinata x tanto sono tutte uguali
  		TEST=$(convert try.png -format '%[pixel:p{'${PIXEL_CORNER_ANSWER_1_X}','${Y}'}]' info:-)
  		if [ ${TEST} = "${CORRECT_ANSWER_COLOR}" ]; then
  			log "Trovato alla coordinata Y:$Y"
  			echo "${X_CENTER_ANSWER} ${Y}" > "kb/question-${QUESTION_HASH}.txt"
  	 		cp question.png "kb/question-${QUESTION_HASH}.png"
  	 		cp screenshot.png "kb/question-${QUESTION_HASH}-full.png"
  			FOUND="Ok"
  			break
  		fi
  	done
  	if [ "${FOUND}" != "Ok" ]; then
  		log "Not found (lost somewhere?). Exiting..."
		if [ "${EMULATED_DEVICE}" = "true" ]; then
			kill $EMULATOR_PID
		fi
		mv screenshot.png "`date '+%Y-%m-%d_%H.%M.%S'`-crashed-screenshot.png"
  		exit 1
  	fi
  	
  	#ok: srgba(77,206,11,1) srgba(73,210,0,1)
  	#ko: srgba(219,16,11,1)
  else
  	#conosco la domanda
  	log "tap sulla risposta"
  	exec_timeout 1800 adb ${DEVICE_OPTS} shell input tap ${COORD}
  	#sleep 1.15
  fi
  
  log "Coordinate: ${COORD}"
  log "-----------------------------------------------------"

done

#adb ${DEVICE_OPTS} shell svc power stayon false

