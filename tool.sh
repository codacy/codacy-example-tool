#!/usr/bin/env bash

function load_config_file {
  local dummycfg_path=/src/dummy.cfg

  if [ -f $dummycfg_path ]; then
    codacy_foobar_parameter="$(tr -d '\n' < "$dummycfg_path")"
  fi
  codacy_patterns="foobar"
}

function load_src_files {
  codacy_files=$(cd /src || exit; find . -type f -exec echo {} \; | cut -c3-)
}

if [ -f /.codacyrc ]; then
  #parse
  codacyrc_file=$(jq -erM '.' < /.codacyrc)

  # error on invalid json
  if [ $? -ne 0 ]; then
    echo "Can't parse .codacyrc file"
    exit 1
  fi

  codacy_files=$(jq -cer '.files | .[]' <<< "$codacyrc_file")
  codacy_patterns="$(jq -cer ".tools | .[] | select(.name==\"dummy\") | .patterns | .[].patternId" <<< "$codacyrc_file")"
  codacy_foobar_parameter="$(jq -cer ".tools | .[] | select(.name==\"dummy\") | .patterns | .[].parameters | select(. != null) | .[] | select(.name==\"value\") | .value" <<< "$codacyrc_file")"

  if [ $? -ne 0 ]; then
    unset codacy_foobar_parameter
  fi

  # When no supplied patterns
  if [ "$codacy_patterns" == "" ]; then
    load_config_file
  fi

  # When no files given, run with all files in /src
  if [ "$codacy_files" == "" ]; then
    load_src_files
  fi
else
  load_config_file
  load_src_files
fi

function has_pattern {
  local pattern="$1"
  if [[ $codacy_patterns =~ (^|[[:space:]])"$pattern"($|[[:space:]]) ]] ; then
    return 0
  else
    return 1
  fi
}

function report_error {
  local file="$1"
  local output="$2"
  echo "{\"filename\":\"$file\",\"message\":\"found $output\",\"patternId\":\"foobar\",\"line\":1}"
}

function analyze_file {
  local file="$1"
  final_file="/src/$file"
  if [ -f "$final_file" ]; then
    if has_pattern "foobar" ; then
      output=$(tr -d '\n' < "$final_file")
      if [[ "$codacy_foobar_parameter" != "" ]]; then
        if [[ "$codacy_foobar_parameter" == "$output" ]]; then
          report_error "$file" "$output"
        fi
      elif [[ "$output" != "" ]]; then
        report_error "$file" "$output"
      fi
    else
      echo "Pattern not found"
      exit 1
    fi
  else
    echo "{\"filename\":\"$final_file\",\"message\":\"could not parse the file\"}"
  fi
}

while read -r file; do
  analyze_file "$file"
done <<< "$codacy_files"
