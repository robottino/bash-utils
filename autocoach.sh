#!/bin/bash

#adb ${DEVICE_OPTS} shell svc power stayon true
#while true; do ./autocoach.sh 7EX0217A30000909; done

#load parameters
. emu-Nexus5-game3.cfg
echo "DEVICE_RESOLUTION=$DEVICE_RESOLUTION"

#CROP_OPTIONS="825x393+234+327"
#CROP_OPTIONS="120x120+567+471"
#CROP_OPTIONS="50x200+620+470"
#CROP_OPTIONS="25x200+620+470"

function resetApp {

	echo "Restarting the application..."
	#chiudo app
	adb ${DEVICE_OPTS} shell am force-stop com.axa.pocketcoach.prod
	sleep 10

	#avvio
	adb ${DEVICE_OPTS} shell am start com.axa.pocketcoach.prod/com.teachonmars.lom.SplashActivity
	sleep 8

	#swipe per trovare corso
	adb ${DEVICE_OPTS} shell input swipe ${SWIPE_CORSO}
	sleep 3

	#tap corso
	adb ${DEVICE_OPTS} shell input tap ${TAP_CORSO}
	sleep 2

	#swipe sfida
	adb ${DEVICE_OPTS} shell input swipe ${SWIPE_SFIDA}
	sleep 3

	#tap sfida
	adb ${DEVICE_OPTS} shell input tap ${TAP_SFIDA}
	sleep 2

	#tap avversario casuale
	adb ${DEVICE_OPTS} shell input tap ${TAP_AVVERSARIO_CASUALE}
	sleep 3

	#tap si
	adb ${DEVICE_OPTS} shell input tap ${TAP_INIZIA_SFIDA_SI}
	sleep 4.3
}

################ BEGIN

if [ "$1" != "" ]; then
        echo "Parametro: $1"
		DEVICE_OPTS="-s $1"
else
        echo "Nessun parametro"
		DEVICE_OPTS=""
fi
echo "DEVICE_OPTS=$DEVICE_OPTS"

resetApp

while true; do

  #adb ${DEVICE_OPTS} shell "screencap -p > /sdcard/screenshot.png" && adb ${DEVICE_OPTS} pull /sdcard/screenshot.png screenshot.png && convert screenshot.png -crop "${CROP_OPTIONS}" question.png
  adb ${DEVICE_OPTS} exec-out screencap -p > screenshot.png && convert screenshot.png -crop "${CROP_OPTIONS}" question.png
  
  #150,1800 --> se è blu è finito il gioco
  TEST=$(convert screenshot.png -format '%[pixel:p{'${PIXEL_TEST_FINE_GIOCO}'}]' info:-)
  echo $TEST
  if [ "${TEST}" = "${PIXEL_TEST_FINE_GIOCO_EXPECTED_VALUE}" ]; then
  	echo "fine gioco"
  	adb ${DEVICE_OPTS} shell input tap ${TAP_FINE_DUELLO_CONTINUA}
  	sleep 3
  	adb ${DEVICE_OPTS} shell input tap ${TAP_FINE_DUELLO_MESSAGGIO_CONTINUA}
  	sleep 4
  
  	#avversario casuale
  	adb ${DEVICE_OPTS} shell input tap ${TAP_AVVERSARIO_CASUALE}
  	sleep 5
  	#si
  	adb ${DEVICE_OPTS} shell input tap ${TAP_INIZIA_SFIDA_SI}
  	sleep 4.3
  	#adb ${DEVICE_OPTS} shell "screencap -p > /sdcard/screenshot.png" && adb ${DEVICE_OPTS} pull /sdcard/screenshot.png screenshot.png && convert screenshot.png -crop "${CROP_OPTIONS}" question.png
  	adb ${DEVICE_OPTS} exec-out screencap -p > screenshot.png && convert screenshot.png -crop "${CROP_OPTIONS}" question.png
  	#exit 1
  fi
  
  COORD="none"
  
  #controllo se ho già incontrato questa domanda
  QUESTION_HASH=$(convert question.png bmp:- | sha1sum)
  if [ -f "kb/question-${QUESTION_HASH}.txt" ]; then
  	COORD=$(cat "kb/question-${QUESTION_HASH}.txt")
  	echo "Domanda già incontrata. Coordinate risposta esatta: ${COORD}"
  fi
  
  if [ "${COORD}" = "none" ]; then
  	#non conosco la domanda, provo la prima
  	echo "Domanda nuova, clicco la prima risposta..."
  	Y=$(echo ${PIXEL_CORNER_ANSWER_1} | cut -d\, -f2)
  	echo "adb ${DEVICE_OPTS} shell input tap ${X_CENTER_ANSWER} ${Y}"
  	adb ${DEVICE_OPTS} shell input tap ${X_CENTER_ANSWER} ${Y}
  	
  	sleep 0.3
  	adb ${DEVICE_OPTS} exec-out screencap -p > try.png
  	#adb ${DEVICE_OPTS} shell "screencap -p > /sdcard/screenshot.png" && adb ${DEVICE_OPTS} pull /sdcard/screenshot.png try.png
  	sleep 1.5
  	
  	#cerco il box verde
  	#TODO: alla fine il verde dura di piu
  	for Y in ${PIXEL_CORNER_ANSWER_1_Y} ${PIXEL_CORNER_ANSWER_2_Y} ${PIXEL_CORNER_ANSWER_3_Y} ${PIXEL_CORNER_ANSWER_4_Y}; do 
  		echo "cerco il verde alla coordinata: $Y"
  		# uso una domanda qualsiasi come coordinata x tanto sono tutte uguali
  		TEST=$(convert try.png -format '%[pixel:p{'${PIXEL_CORNER_ANSWER_1_X}','${Y}'}]' info:-)
  		if [ ${TEST} = "${CORRECT_ANSWER_COLOR}" ]; then
  			echo "Trovato alla coordinata Y:$Y"
  			echo "${X_CENTER_ANSWER} ${Y}" > "kb/question-${QUESTION_HASH}.txt"
  	 		cp question.png "kb/question-${QUESTION_HASH}.png"
  	 		cp screenshot.png "kb/question-${QUESTION_HASH}-full.png"
  			FOUND="Ok"
  			break
  		fi
  	done
  	if [ "${FOUND}" != "Ok" ]; then
  		echo "Not found (lost somewhere?). Exiting..."
  		exit 1
  	fi
  	
  	#ok: srgba(77,206,11,1) srgba(73,210,0,1)
  	#ko: srgba(219,16,11,1)
  else
  	#conosco la domanda
  	adb ${DEVICE_OPTS} shell input tap ${COORD}
  	sleep 1.15
  fi
  
  echo "Coordinate: ${COORD}"
  DATE=`date '+%Y-%m-%d %H:%M:%S'`
  echo ""
  echo "-- $DATE --------------------------------------------"
  echo ""

done

echo "exiting..."
#adb ${DEVICE_OPTS} shell svc power stayon false

