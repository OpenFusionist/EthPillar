#!/bin/bash

# Author: coincashew.eth | coincashew.com
# License: GNU GPL
# Source: https://github.com/coincashew/ethpillar
#
# Made for home and solo stakers 🏠🥩

# Load functions
BASE_DIR=$(pwd)
source $BASE_DIR/functions.sh

function getClient(){
	CL=$(cat /etc/systemd/system/consensus.service | grep Description= | awk -F'=' '{print $2}' | awk '{print $1}')
}

function promptYesNo(){
	if whiptail --title "Resync Consensus - $CL" --yesno "This will only take a minute or two.\nAre you sure you want to resync $CL?" 9 78; then
		resyncClient
		promptViewLogs
	fi
}

function promptViewLogs(){
	if whiptail --title "Resync $CL complete" --yesno "Would you like to view logs and confirm everything is running properly?" 8 78; then
		sudo bash -c 'journalctl -fu consensus | ccze -A'
	fi
}

function resyncClient(){
	case $CL in
	  Lighthouse)
		sudo systemctl stop consensus
		sudo rm -rf /var/lib/lighthouse/beacon
		sudo systemctl restart consensus
		;;
	  Lodestar)
		sudo systemctl stop consensus
		sudo rm -rf /var/lib/lodestar/chain-db
		sudo systemctl restart consensus
		;;
	  Teku)
		sudo systemctl stop consensus
		sudo rm -rf /var/lib/teku/beacon
		sudo systemctl restart consensus
		;;
	  Nimbus)
		getNetwork
		case $NETWORK in
		Holesky)
			URL="https://holesky.beaconstate.ethstaker.cc"
			;;
		Mainnet)
			URL="https://beaconstate.ethstaker.cc"
			;;
		Sepolia)
			URL="https://sepolia.beaconstate.info"
			;;
		Ephemery)
			URL="https://ephemery.beaconstate.ethstaker.cc"
			;;
		"Endurance Mainnet")
			URL="https://checkpointz.fusionist.io"
			;;
		"Endurance Devnet")
			URL="http://78.46.91.61:9781"
			;;
		esac

		sudo systemctl stop consensus
		sudo rm -rf /var/lib/nimbus/db

		# Set network configuration
		NETWORK_LOWER=$(echo $NETWORK | tr '[:upper:]' '[:lower:]')
		NETWORK_CONFIG=$NETWORK_LOWER
		if [[ "$NETWORK_LOWER" == "endurance mainnet" || "$NETWORK_LOWER" == "endurance devnet" ]]; then
			echo "For Endurance network, using custom network config: /opt/ethpillar/el-cl-genesis-data"
			NETWORK_CONFIG="/opt/ethpillar/el-cl-genesis-data"
		fi

		sudo -u consensus /usr/local/bin/nimbus_beacon_node trustedNodeSync \
		--network=$NETWORK_CONFIG \
		--trusted-node-url=$URL \
		--data-dir=/var/lib/nimbus \
		--backfill=false

		sudo systemctl restart consensus
		;;
	  Prysm)
		sudo systemctl stop consensus
		sudo rm -rf /var/lib/prysm/beacon/beaconchaindata
		sudo systemctl restart consensus
		;;
	  esac
}

function setWhiptailColors(){
	export NEWT_COLORS='root=,black
border=green,black
title=green,black
roottext=red,black
window=red,black
textbox=white,black
button=black,green
compactbutton=white,black
listbox=white,black
actlistbox=black,white
actsellistbox=black,green
checkbox=green,black
actcheckbox=black,green'
}

setWhiptailColors
getClient
promptYesNo