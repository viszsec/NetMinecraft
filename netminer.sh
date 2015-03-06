#!/bin/bash

function show_help {
  echo "Netminer - Applies a Wireshark filter to many PCAP files and merges"
  echo "the results into one file."
  echo "Usage: $0 -s <directory> -f <filter> -w <output_file>"
  echo ""
  echo -e '    -s <directory>\n\t\tSpecifies the directory containing the'
  echo -e '    \t\pcap files to mine.'
  echo -e '    -f <filter>\n\t\tWireshark-style filter to apply to each pcap.'
  echo -e '    -w <output_file>\n\t\tPcap file to store the results to.'
}

# Verify if any arguments were given
# if not, exit
if [ $# -eq 0 ];
then
    show_help
    exit 0
fi


# Reset in case getopts has been used previously in the shell.
OPTIND=1
SRC_PCAP=""
FILTER=""
OUTPUT_FILE=""

while getopts "h?s:f:w:" opt;
do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    s)  SRC_PCAP=$OPTARG
        ;;
    r)  FILTER=$OPTARG
        ;;
    w)  OUTPUT_FILE=$OPTARG
        ;;
    esac
done

if [ -z $SRC_PCAP ]; then
  echo "[-] No source were specified. Please specify the location of the pcap files."
  exit 1
fi

if [ -z $FILTER ]; then
  echo "[-] No filter specified."
  exit 1
fi

echo "[!] Warning: make sure your filter is strict. Otherwise the resulting file will be huge."
echo -n "[?] Continue? [Y/n]"
read -n 1 answer
if [ "$answer" == "n" ]; then
  echo ""
  exit 0
fi

DIR_TEMP=$(mktemp -d)
echo "[*] Temporary folder: $DIR_TEMP"

for file_pcap in $SRC_PCAP/*.pcap; do
  echo "[*] $file_pcap ..."
  FILE_TEMP=$(mktemp -p $DIR_TEMP pcap.XXXXXXX) || exit 1
  echo "[*] Storing results in $FILE_TEMP..."
  tshark -n -2 -r $file_pcap -w $FILE_TEMP -R "$FILTER"
  if [ -e $FILE_TEMP ]; then
    mergecap -w $FILE_OUTPUT $FILE_TEMP
#    rm -f $FILE_TEMP
  fi

done

echo "[*] Removing temporary files..."
rm -Rf $DIR_TEMP
echo "[+] Completed. Terminating..."
