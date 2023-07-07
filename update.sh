#!/bin/bash

NAMESPACE=stripo

helm repo update

# To check the status of the previous execution
function check_result {
  if [[ "$?" -ne 0 ]] ; then
          echo "========================================"
          echo "-========= Update faild ===============-"
          echo "========================================"
          exit 1
  fi
}

function update {
    service_name=$1
    if [[ "$service_name" == "" ]] ; then 
        echo "Service name not set"
        exit 1
    fi
    echo "-= Start update $service_name =-"
    echo -ne '##                        (5%)\r'
    check_result
    echo -ne '###                       (10%)\r'
    CHECK_INSTALL=`helm list --namespace=$NAMESPACE | grep $service_name`
    helm upgrade --install $service_name stripo/$service_name -f $service_name.yaml --namespace $NAMESPACE
    check_result
    echo -ne '#############             (57%)\r'
    kubectl rollout status deploy/$service_name --namespace=$NAMESPACE
    check_result
    echo -ne '###########################(100%)\r'
    echo "========================================"
    echo "-== Update $service_name success ==-"
    echo "========================================"
}

update $1
