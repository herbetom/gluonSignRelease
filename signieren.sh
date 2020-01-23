#!/bin/bash
# basiert auf https://github.com/FreiFunkMuenster/tools/blob/master/signieren.sh
# benötigt:
#   - sshfs
#   - ecdsautils (https://github.com/tcatm/ecdsautils)
#   - sign.sh und sigtest.sh aus dem Gluon Repo (https://github.com/freifunk-gluon/gluon/tree/master/contrib)
#     (liegen im Ordner gluonContrib und lassen sich durch ausführen von update.sh updaten)

if [ ! -f "config.sh" ]; then
    printf "estelle dir eine config.sh. Ein Beispiel ist in config-example.sh zu finden.\n"
    exit;
fi
source config.sh
PATH_TO_SECRET_SIG_KEY='secret-temp'
FIRMWARESERVER_MOUNTPOINT='firmwareserver-mount'

# trap ctrl-c and call cleanupAndExit
trap cleanupAndExit INT

function cleanupAndExit() {
    printf "\ncleanup and exit\n"
    fusermount -u $FIRMWARESERVER_MOUNTPOINT
    [ -e "$PATH_TO_SECRET_SIG_KEY" ] && rm $PATH_TO_SECRET_SIG_KEY
    [ -e "$FIRMWARESERVER_MOUNTPOINT" ] && rm -r $FIRMWARESERVER_MOUNTPOINT
    exit;
}

mkdir -p $FIRMWARESERVER_MOUNTPOINT
sshfs $FIRMWARESERVER_OPTIONS $FIRMWARESERVER_HOST:$FIRMWARESERVER_PATH $FIRMWARESERVER_MOUNTPOINT

echo "possible versions: "
ls -td -- $FIRMWARESERVER_MOUNTPOINT/*-*/ | cut -d'/' -f2

read -p "Version: " -e -i "$(ls -td -- $FIRMWARESERVER_MOUNTPOINT/*-*/ | head -n 1 | cut -d'/' -f2)" VERSION
if [ "$VERSION" = "" ] ; then
    printf "Du musst eine Version angeben!";
    cleanupAndExit
fi

read -p "Branches? (experimental beta stable): " -e -i experimental BRANCHES
if [ "$BRANCHES" = "" ] ; then
    printf "Du musst einen oder mehrere Branches (experimental beta stable) angeben!";
    cleanupAndExit
fi

storeSecretKey

if [ -s "$PATH_TO_SECRET_SIG_KEY" ]
then 
    for b in $BRANCHES
    do
	./gluonContrib/sigtest.sh $PUBLIC_SIG_KEY $FIRMWARESERVER_MOUNTPOINT/$VERSION/images/sysupgrade/$b-$VERSION.manifest
        
        RESULT=$?
        if [ $RESULT -eq 0 ] ; then
            printf "$VERSION ist bereits durch dich als $b signiert." 
        else  

            ./gluonContrib/sign.sh $PATH_TO_SECRET_SIG_KEY $FIRMWARESERVER_MOUNTPOINT/$VERSION/images/sysupgrade/$b-$VERSION.manifest
            ./gluonContrib/sigtest.sh $PUBLIC_SIG_KEY $FIRMWARESERVER_MOUNTPOINT/$VERSION/images/sysupgrade/$b-$VERSION.manifest

            RESULT=$?

            if [ $RESULT -eq 1 ] ; then
                printf "Signieren von Version $VERSION als $b fehlgeschlagen!\n";
            elif [ $RESULT -eq 0 ] ; then
                printf "Signieren von Version $VERSION als $b erfolgreich!\n";
            else
                printf "Signieren von Version $VERSION als $b fehlgeschlagen mit Fehlercode $? !\n";
            fi
        fi
    done
fi

cleanupAndExit