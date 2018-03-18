#!/bin/bash

# Script that export the images data from a spesific location to a CSV file and exports all the images from URL into a directory.

working_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
red='\033[0;31m'
nored='\033[0m'
green='\033[0;32m'
nogreen='\033[0m'
function usage {
  echo -e "${green}$0${nogreen} ${red}-a account${nored}"
  echo ""
  exit 0
}

function mysql_query {
  if [[ ! -d "${working_dir}/csv_"${AccountID}"" ]]; then
    mkdir -p ${working_dir}/csv_"${AccountID}"
    chmod -R 755 ${working_dir}/csv_"${AccountID}"
  fi

  HOST=$(mysql _config -Ne "select db_field from db_table where db_field = \"${AccountID}\";")
  mysql -h${HOST} ${AccountID} -e "SELECT
  p.db_field AS SKU,
  CONCAT('http://xxxxxxx.cloudfront.net/d/${AccountID}/images/gallery/thumbnails','/',image.image_id,'/',image.image_version,'/',image.db_field) AS image,
  p.db_field,
  image.db_field
  FROM db_table p
  LEFT JOIN db_table pi ON(p.products_id = pi.product_id)
  LEFT JOIN db_table ON (image.image_id =pi.image_id)
  WHERE image.db_field IS NOT NULL;" | sed 's/\t/","/g;s/^/"/;s/$/"/;s/\n//g' > ${working_dir}/csv_${AccountID}/${AccountID}_prod_images.csv
}

# Pull all the image URL's from the CSV file and export all the images into the pics directory
function get_url {
  url=$(awk -F "\"*,\"*" '{print $2}' ${working_dir}/csv_"${AccountID}"/"${AccountID}"_prod_images.csv)
  echo "${url}"
}

function get_images {
  if [[ ! -d "${working_dir}/pics_"${AccountID}"" ]]; then
    mkdir -p ${working_dir}/pics_"${AccountID}"
    chmod -R 755 ${working_dir}/pics_"${AccountID}"
  fi
  wget ${url} -P ${working_dir}/pics_"${AccountID}"
}

AccountID='blank'
# make sure each option is used only once
if ( ! getopts ":a:h" opt); then
  usage
  exit 1;
fi

# options
while getopts ":a:h" opt; do
  case $opt in
    a)
      AccountID="$OPTARG"
      ;;
    h)
      usage
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ "${AccountID}" == 'blank' ]];then
  usage
else
  mysql_query
  get_url
  get_images
fi
