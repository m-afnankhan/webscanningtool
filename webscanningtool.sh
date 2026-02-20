#!/bin/bash

# ==========================================
# AK--9 Web Vulnerability Scanner PAK
# Author: Afnan Khan
# Version: 1.0
# ==========================================

# ----------- Colors -------------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
WHITE="\e[97m"
RESET="\e[0m"

# ----------- Banner -------------
banner() {
clear
echo -e "${CYAN}"
echo "======================================================="
echo "        AK--9 Web Vulnerability Scanner PAK"
echo "======================================================="
echo -e "${RESET}"
}

# ----------- Input -------------
get_target() {
echo -ne "${YELLOW}Enter Target Domain (example.com): ${RESET}"
read DOMAIN

echo -ne "${YELLOW}Protocol (1) HTTP  (2) HTTPS : ${RESET}"
read PROTO

if [ "$PROTO" == "1" ]; then
    URL="http://$DOMAIN"
else
    URL="https://$DOMAIN"
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="$(pwd)/AK9_Report_$DOMAIN_$TIMESTAMP"
mkdir -p "$OUTPUT_DIR/logs"
}

# ----------- Tool Functions -------------

run_nikto() {
echo -e "${BLUE}[+] Running Nikto...${RESET}"
nikto -h "$URL" > "$OUTPUT_DIR/logs/nikto.txt" 2>&1
}

run_nuclei() {
echo -e "${BLUE}[+] Running Nuclei...${RESET}"
nuclei -u "$URL" > "$OUTPUT_DIR/logs/nuclei.txt" 2>&1
}

run_whatweb() {
echo -e "${BLUE}[+] Running WhatWeb...${RESET}"
whatweb "$URL" > "$OUTPUT_DIR/logs/whatweb.txt" 2>&1
}

run_gobuster() {
echo -e "${BLUE}[+] Running Gobuster...${RESET}"
gobuster dir -u "$URL" -w /usr/share/wordlists/dirb/common.txt \
> "$OUTPUT_DIR/logs/gobuster.txt" 2>&1
}

run_dirsearch() {
echo -e "${BLUE}[+] Running Dirsearch...${RESET}"
dirsearch -u "$URL" \
-o "$OUTPUT_DIR/logs/dirsearch.txt" >/dev/null 2>&1
}

run_wpscan() {
echo -e "${BLUE}[+] Running WPScan...${RESET}"
wpscan --url "$URL" --no-update \
-o "$OUTPUT_DIR/logs/wpscan.txt"
}

run_sqlmap() {
echo -e "${BLUE}[+] Running SQLMap (Basic Crawl)...${RESET}"
sqlmap -u "$URL" --batch --crawl=1 \
> "$OUTPUT_DIR/logs/sqlmap.txt" 2>&1
}

run_xsstrike() {
echo -e "${BLUE}[+] Running XSStrike...${RESET}"
xsstrike -u "$URL" \
> "$OUTPUT_DIR/logs/xsstrike.txt" 2>&1
}

run_dalfox() {
echo -e "${BLUE}[+] Running Dalfox...${RESET}"
dalfox url "$URL" \
> "$OUTPUT_DIR/logs/dalfox.txt" 2>&1
}

# ----------- HTML Report -------------
generate_report() {

REPORT="$OUTPUT_DIR/AK9_Report.html"

cat <<EOF > $REPORT
<!DOCTYPE html>
<html>
<head>
<title>AK--9 Scan Report</title>
<style>
body { background:#0f172a; color:white; font-family:Arial; }
h1 { color:#38bdf8; }
.section { margin-bottom:40px; }
pre { background:#1e293b; padding:15px; overflow:auto; }
a { color:#22d3ee; }
</style>
</head>
<body>
<h1>AK--9 Web Vulnerability Scanner Report</h1>
<p><b>Target:</b> $URL</p>
<p><b>Date:</b> $(date)</p>
<hr>
EOF

for file in $OUTPUT_DIR/logs/*.txt; do
tool=$(basename "$file")
echo "<div class='section'>" >> $REPORT
echo "<h2>$tool</h2>" >> $REPORT
echo "<a href='logs/$tool'>Open Raw Log</a>" >> $REPORT
echo "<pre>" >> $REPORT
cat "$file" >> $REPORT
echo "</pre></div>" >> $REPORT
done

echo "</body></html>" >> $REPORT

echo -e "${GREEN}[+] Report Generated: $REPORT${RESET}"
}

# ----------- Schedule -------------
schedule_scan() {
echo -ne "${YELLOW}Enter time (HH:MM 24hr format): ${RESET}"
read TIME
HOUR=$(echo $TIME | cut -d: -f1)
MIN=$(echo $TIME | cut -d: -f2)

(crontab -l 2>/dev/null; echo "$MIN $HOUR * * * bash $(pwd)/$0") | crontab -
echo -e "${GREEN}[+] Scan Scheduled Daily at $TIME${RESET}"
}

# ----------- Menu -------------
menu() {
echo -e "${CYAN}
1. Nikto
2. Nuclei
3. WhatWeb
4. Gobuster
5. Dirsearch
6. WPScan
7. SQLMap
8. XSStrike
9. Dalfox
10. Scan All
11. Schedule Scan
0. Exit
${RESET}"

echo -ne "${YELLOW}Select Option: ${RESET}"
read OPTION

case $OPTION in
1) run_nikto ;;
2) run_nuclei ;;
3) run_whatweb ;;
4) run_gobuster ;;
5) run_dirsearch ;;
6) run_wpscan ;;
7) run_sqlmap ;;
8) run_xsstrike ;;
9) run_dalfox ;;
10)
run_nikto
run_nuclei
run_whatweb
run_gobuster
run_dirsearch
run_wpscan
run_sqlmap
run_xsstrike
run_dalfox
;;
11) schedule_scan ;;
0) exit ;;
*) echo "Invalid Option" ;;
esac
}

# ----------- Main -------------
banner
get_target
menu
generate_report

echo -ne "${YELLOW}Open report now? (y/n): ${RESET}"
read OPEN

if [ "$OPEN" == "y" ]; then
xdg-open "$OUTPUT_DIR/AK9_Report.html"
fi

echo -e "${GREEN}Scan Completed.${RESET}"