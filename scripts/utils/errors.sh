#!/usr/bin/env bash
fatal() {
  local E
  E="${1:-Unknown Error.}"
  echo "FATAL: $E." 
  exit 1
}
