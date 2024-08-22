#!/bin/bash

NAMESPACE=stripo

helm repo update stripo

# To check the status of the previous execution
function check_result {
  if [[ "$?" -ne 0 ]] ; then
          echo "========================================"
          echo "-=========== Update failed ============-"
          echo "========================================"
#          exit 1
  fi
}

function update {
    service_name=$1
    if [[ "$service_name" == "" ]] ; then
        echo "Service name not set"
        exit 1
    fi
    echo "-= Start update $service_name =-"
    if [ "$service_name" = "coediting-core-service" ] || [ "$service_name" = "env-adapter-service" ] || [ "$service_name" = "merge-service" ]; then
      helm upgrade --install $service_name stripo/go-template-service -f $service_name.yaml --namespace $NAMESPACE
    else
      helm upgrade --install $service_name stripo/$service_name -f $service_name.yaml --namespace $NAMESPACE
    fi
    kubectl rollout restart deploy/$service_name --namespace=$NAMESPACE
    echo -ne '###########################(100%)\r'
    echo "========================================"
    echo "-== Update $service_name success ==-"
    echo "========================================"
}

echo "-== Updating =--"
echo -ne '#                         (2%)\r'
update "stripo-security-service"
check_result
echo -ne '##                        (5%)\r'
update "emple-ui"
check_result
echo -ne '###                       (10%)\r'
update "stripo-plugin-proxy-service"
check_result
echo -ne '#####                     (23%)\r'
update "stripo-plugin-statistics-service"
check_result
echo -ne '#######                   (31%)\r'
update "stripo-plugin-details-service"
check_result
echo -ne '########                  (37%)\r'
update "ai-service"
check_result
echo -ne '##########                (41%)\r'
update "screenshot-service"
check_result
echo -ne '###########               (45%)\r'
update "stripo-plugin-documents-service"
check_result
echo -ne '############              (53%)\r'
update "stripo-plugin-image-bank-service"
check_result
echo -ne '#############             (57%)\r'
update "stripo-plugin-custom-blocks-service"
check_result
echo -ne '##############            (60%)\r'
update "stripe-html-gen-service"
check_result
echo -ne '###############           (69%)\r'
update "patches-service"
check_result
echo -ne '#################         (75%)\r'
update "amp-validator-service"
check_result
echo -ne '###################       (82%)\r'
update "stripe-html-cleaner-service"
check_result
echo -ne '#####################     (89%)\r'
update "stripo-plugin-api-gateway"
check_result
echo -ne '#######################    (91%)\r'
update "stripo-plugin-details-service"
check_result
echo -ne '########################   (92%)\r'
update "stripo-plugin-drafts-service"
check_result
echo -ne '########################## (97%)\r'
update "countdowntimer"
check_result
echo -ne '########################## (99%)\r'
update "stripo-timer-api"
