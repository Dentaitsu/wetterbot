#!/bin/bash

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
CYAN="\033[36m"
YELLOW="\033[33m"
WHITE="\033[37m"
RESET="\033[0m"

API_KEY="b20e0352d9e922c3796be1ac85591f6b"
API_URL="https://api.openweathermap.org/data/2.5"

get_weather() {
  local location="$1"
  local unit="metric"
  local lang="de"

  local current_weather=$(curl -s "${API_URL}/weather?q=${location}&units=${unit}&lang=${lang}&appid=${API_KEY}")

  if [[ $(echo "$current_weather" | jq -r '.cod') != "200" ]]; then
    echo -e "${RED}❌ Fehler: Stadt oder Land nicht gefunden oder API-Fehler!${RESET}"
    return 1
  fi

  local temp=$(echo "$current_weather" | jq -r '.main.temp')
  local feels_like=$(echo "$current_weather" | jq -r '.main.feels_like')
  local weather=$(echo "$current_weather" | jq -r '.weather[0].description')
  local humidity=$(echo "$current_weather" | jq -r '.main.humidity')
  local wind_speed=$(echo "$current_weather" | jq -r '.wind.speed')
  local location_name=$(echo "$current_weather" | jq -r '.name')
  local country=$(echo "$current_weather" | jq -r '.sys.country')

  echo -e "${CYAN}🌦️ Aktuelles Wetter in ${WHITE}${location_name}, ${country}:${RESET}"
  echo -e "  ${YELLOW}🌡️ Temperatur:${RESET} ${temp}° (Gefühlt: ${feels_like}°)"
  echo -e "  ${BLUE}🌬️ Windgeschwindigkeit:${RESET} ${wind_speed} m/s"
  echo -e "  ${GREEN}💧 Luftfeuchtigkeit:${RESET} ${humidity}%"
  echo -e "  ${CYAN}🌥️ Wetterlage:${RESET} ${weather}"
}

get_forecast() {
  local location="$1"
  local unit="metric"
  local lang="de"

  local forecast=$(curl -s "${API_URL}/forecast?q=${location}&units=${unit}&lang=${lang}&appid=${API_KEY}")

  if [[ $(echo "$forecast" | jq -r '.cod') != "200" ]]; then
    echo -e "${RED}❌ Fehler: Vorhersagedaten konnten nicht abgerufen werden!${RESET}"
    return 1
  fi

  echo -e "${CYAN}📅 3-Tage-Wettervorhersage für ${WHITE}${location}:${RESET}"
  for i in 1 2 3; do
    local day=$(date -d "+$i day" +%Y-%m-%d)
    local day_forecast=$(echo "$forecast" | jq -r --arg DATE "$day" '.list[] | select(.dt_txt | startswith($DATE))')
    local temp=$(echo "$day_forecast" | jq -r '.main.temp' | head -1)
    local weather=$(echo "$day_forecast" | jq -r '.weather[0].description' | head -1)
    echo -e "  ${WHITE}📅 Tag $i ($day):${RESET} ${YELLOW}🌡️ $temp°${RESET}, ${CYAN}🌥️ $weather${RESET}"
  done
}

get_uv_index() {
  local location="$1"

  local current_weather=$(curl -s "${API_URL}/weather?q=${location}&appid=${API_KEY}")

  if [[ $(echo "$current_weather" | jq -r '.cod') != "200" ]]; then
    echo -e "${RED}❌ Fehler: UV-Index-Daten konnten nicht abgerufen werden!${RESET}"
    return 1
  fi

  local lat=$(echo "$current_weather" | jq -r '.coord.lat')
  local lon=$(echo "$current_weather" | jq -r '.coord.lon')
  local uv_data=$(curl -s "${API_URL}/uvi?lat=${lat}&lon=${lon}&appid=${API_KEY}")

  if [[ -z "$uv_data" ]]; then
    echo -e "${RED}❌ Fehler: Keine UV-Index-Daten verfügbar.${RESET}"
    return 1
  fi

  local uv_index=$(echo "$uv_data" | jq -r '.value')
  echo -e "${CYAN}☀️ Aktueller UV-Index für ${WHITE}${location}:${RESET} ${YELLOW}$uv_index${RESET}"
}

while true; do
  echo -e "${GREEN}🌍 Willkommen beim Wettervorhersage-Bot!${RESET}"
  read -p "$(echo -e "${CYAN}🏙️ Bitte gib eine Stadt oder ein Land ein:${RESET} ")" location

  get_weather "$location"
  if [[ $? -eq 0 ]]; then
    echo ""
    get_forecast "$location"
    echo ""
    get_uv_index "$location"
  fi

  echo ""
  read -p "$(echo -e "${BLUE}🔁 Möchtest du eine weitere Abfrage durchführen? (j/n):${RESET} ")" repeat
  if [[ "$repeat" != "j" && "$repeat" != "J" ]]; then
    echo -e "${GREEN}👋 Vielen Dank, dass du den Wettervorhersage-Bot genutzt hast!${RESET}"
    break
  fi
  echo ""
done
