#!/bin/bash
VER=1.0
#--[ Info ]-----------------------------------------------------#
#
# This script comes without any warranty, use it at your own risk.
#
# Changelog
# 20XX-00-00 v.1x Orginale creator Sokar aka PicdleRick
# 2020-04-18 v.2x Code modifications and improvements Teqno/TeRRaNoVA
#
# Installation: copy TVMaze_nuke.sh to glftpd/bin and chmod it
# 755. Copy the modificated TVMaze.tcl into your eggdrop pzs-ng
# plugins dir.
#
# Modify GLROOT into /glftpd or /jail/glftpd.
#
# To ensure log file exist, run: "./TVMaze_nuke.sh sanity" from
# shell, this will create the log file and set the correct
# permissions.
#
#--[ Settings ]-------------------------------------------------#

GLROOT=/glftpd
GLCONF=$GLROOT/etc/glftpd.conf
DEBUG=0
LOG_FILE=$GLROOT/ftp-data/logs/tvmaze_nuke.log

# Username of person to nuke with. This user must be a glftpd user account.
NUKE_USER=glftpd

# Multiplier to use when nuking a release
NUKE_MULTIPLER=5

# Show Types: Animation Award_Show Documentary Game_Show News Panel_Show Reality Scripted Sports Talk_Show Variety
# Space delimited list of show types to nuke.
NUKE_SHOW_TYPES=""

# Show Types: Animation Award_Show Documentary Game_Show News Panel_Show Reality Scripted Sports Talk_Show Variety
NUKE_SECTION_TYPES="
/site/TV-HD:(Sports|Game_Show)
/site/TV-NL:(Sports|Game_Show)
/site/TV-SD:(Sports|Game_Show)
"

# Configured like NUKE_SECTION_TYPES
# Genres: Action Adult Adventure Anime Children Comedy Crime DIY Drama Espionage Family Fantasy Food History Horror Legal Medical Music Mystery Nature Romance Science-Fiction
# Sports Supernatural Thriller Travel War Western
NUKE_SECTION_GENRES="
/site/TV-HD:(Sports|Game_Show)
/site/TV-NL:(Sports|Game_Show)
/site/TV-SD:(Sports|Game_Show)
"

# Space delimited list of episodes with an air date before this year will be nuked
NUKE_EPS_BEFORE_YEAR="2018"

# Space delimited list of TV Shows produced in these countries will be nuked
NUKE_ORIGIN_COUNTRIES="DE"

# 0 = Nuke / 1 = Do not nuke
NUKE_EP_BEFORE_YEAR=0
NUKE_SHOW_TYPE=0
NUKE_SECTION_TYPE=0
NUKE_SECTION_GENRE=0
NUKE_ORIGIN_COUNTRY=0

# Space delimited list of TV shows to never nuke, use releasename and not show name ie use The.Flash and NOT The Flash
ALLOWED_SHOWS=""

# Space delimited list of sections to never nuke
EXCLUDED_SECTIONS="ARCHIVE REQUEST"

# Space delimited list of groups to never nuke ie affils
EXCLUDED_GROUPS=""

#--[ Script Start ]---------------------------------------------#

function LogMsg()
{
    timestamp=`date --rfc-3339=seconds`
    echo "$timestamp $@" >> $LOG_FILE
}

if [ "$1" = "sanity" ]
then
    echo
    echo "Creating log file $LOG_FILE and setting permission 666"
    touch $LOG_FILE ; chmod 666 $LOG_FILE
    exit 0
fi

if [ ! -f $LOG_FILE ]
then
    echo
    echo "Log file $LOG_FILE do not exist, create it by running ./TVMaze_nuke.sh sanity"
    echo
    exit 1
fi

if [ $# -ne 7 ]
then
    echo
    echo "ERROR! Missing arguments."
    echo
    LogMsg "ERROR! Not enough arguments passed in."
    exit 1
fi

# Process args and remove encapsulating double quotes.
RLS_NAME=`sed -e 's/^"//' -e 's/"$//' <<<"$1"`
SHOW_GENRES=`sed -e 's/^"//' -e 's/"$//' <<<"$2"`
SHOW_COUNTRY=`sed -e 's/^"//' -e 's/"$//' <<<"$3"`
SHOW_NETWORK=`sed -e 's/^"//' -e 's/"$//' <<<"$4"`
SHOW_STATUS=`sed -e 's/^"//' -e 's/"$//' <<<"$5"`
SHOW_TYPE=`sed -e 's/^"//' -e 's/"$//' <<<"$6"`
EP_AIR_DATE=`sed -e 's/^"//' -e 's/"$//' <<<"$7"`

if [ "$DEBUG" -eq 1 ]
then
    LogMsg "Release: $RLS_NAME Genres: $SHOW_GENRES Country: $SHOW_COUNTRY Network: $SHOW_NETWORK Status: $SHOW_STATUS Type: $SHOW_TYPE Air date: $EP_AIR_DATE"
fi

for show in $ALLOWED_SHOWS
do
    result=`echo "$RLS_NAME" | grep -i "$show"`
    if [ -n "$result" ]
    then
	if [ "$DEBUG" -eq 1 ]
	then
	    LogMsg "Skipping allowed show: $RLS_NAME"
	fi
        echo "Skipping allowed show: $RLS_NAME"
        exit 0
    fi
done

for group in $EXCLUDED_GROUPS
do
    result=`echo "$RLS_NAME" | grep -i "\-$group"`
    if [ -n "$result" ]
    then
        if [ "$DEBUG" -eq 1 ]
        then
    	    LogMsg "Skipping group: $RLS_NAME"
	fi
        echo "Skipping group: $RLS_NAME"
        exit 0
    fi
done

if [ "$NUKE_SECTION_TYPE" -eq 1 ]
then
    for rawdata in $NUKE_SECTION_TYPES
    do
        section="`echo "$rawdata" | cut -d ':' -f1`"
        denied="`echo "$rawdata" | cut -d ':' -f2`"
        if [ "`echo "$RLS_NAME" | egrep -i "$section/"`" ]
        then
            if [ "`echo $SHOW_TYPE | egrep -i $denied`" ]
            then
                type="`echo $SHOW_TYPE | egrep -oi $denied`"
                $GLROOT/bin/nuker -r $GLCONF -N $NUKE_USER -n {$RLS_NAME} $NUKE_MULTIPLER "$type type of TV show is not allowed"
                LogMsg "Nuked release: {$RLS_NAME} because its show type is $type which is not allowed in section $section."
                exit 0
            fi
        fi
    done
fi

if [ "$NUKE_SECTION_GENRE" -eq 1 ]
then
    for rawdata in $NUKE_SECTION_GENRES
    do
        section="`echo "$rawdata" | cut -d ':' -f1`"
        denied="`echo "$rawdata" | cut -d ':' -f2`"
        if [ "`echo "$RLS_NAME" | egrep -i "$section/"`" ]
        then
            if [ "`echo $SHOW_GENRES | egrep -i $denied`" ]
            then
                genre="`echo $SHOW_GENRES | egrep -oi $denied`"
                $GLROOT/bin/nuker -r $GLCONF -N $NUKE_USER -n {$RLS_NAME} $NUKE_MULTIPLER "$genre genre is not allowed"
                LogMsg "Nuked release: {$RLS_NAME} because its genre is $genre which is not allowed in section $section."
                exit 0
            fi
        fi
    done
fi

if [ "$NUKE_EP_BEFORE_YEAR" -eq 1 ]
then
    if [ -n "$EP_AIR_DATE" ]
    then
        if [ "$EP_AIR_DATE" != "N/A" ]
        then
            ep_air_year=`date +"%Y" -d "$EP_AIR_DATE"`
            if [ -n "$ep_air_year" ]
            then
                if [ "$ep_air_year" -lt $NUKE_EPS_BEFORE_YEAR ]
                then
                    $GLROOT/bin/nuker -r $GLCONF -N $NUKE_USER -n {$RLS_NAME} $NUKE_MULTIPLER "Episode air date must be $NUKE_EPS_BEFORE_YEAR or newer"
                    LogMsg "Nuked release: {$RLS_NAME} because its year of release of $ep_air_year is before $NUKE_EPS_BEFORE_YEAR"
                    exit 0
                fi
            fi
        fi
    fi
fi

if [ "$NUKE_SHOW_TYPE" -eq 1 ]
then
    if [ -n "$NUKE_SHOW_TYPES" ]
    then
        for type in $NUKE_SHOW_TYPES
        do
            if [ "$SHOW_TYPE" == "$type" ]
            then
                $GLROOT/bin/nuker -r $GLCONF -N $NUKE_USER -n {$RLS_NAME} $NUKE_MULTIPLER "$type TV shows are not allowed"
                LogMsg "Nuked release: {$RLS_NAME} because its show type is $SHOW_TYPE which is not allowed."
                exit 0
            fi
        done
    fi
fi

if [ "$NUKE_ORIGIN_COUNTRY" -eq 1 ]
then
    if [ -n "$NUKE_ORIGIN_COUNTRIES" ]
    then
        for country in $NUKE_ORIGIN_COUNTRIES
        do
            if [ "$SHOW_COUNTRY" == "$country" ]
            then
                $GLROOT/bin/nuker -r $GLCONF -N $NUKE_USER -n {$RLS_NAME} $NUKE_MULTIPLER "TV shows from $country are not allowed"
                LogMsg "Nuked release: {$RLS_NAME} because its country of origin is $SHOW_COUNTRY which is not allowed."
                exit 0
            fi
        done
    fi
fi

exit 0