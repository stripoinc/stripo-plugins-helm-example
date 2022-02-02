#!/bin/bash

NAMESPACE=stripo

# To check the status of the previous execution
function check_result {
  if [[ "$?" -ne 0 ]] ; then
          echo "========================================"
          echo "-=========== Install failed ============-"
          echo "========================================"
          exit 1
  fi
}

function install_or_skip {
    service_name=$1
    CHECK_INSTALL=`helm list --namespace=$NAMESPACE | grep $service_name`
    if [[ "$CHECK_INSTALL" == "" ]] ; then
            echo "-= Install $service_name =-"
            helm install $service_name stripo/$service_name -f $service_name.yaml --namespace $NAMESPACE
            kubectl rollout status deploy/$service_name --namespace=$NAMESPACE
    else
        # if you need to update all services, uncomment the line
        #helm upgrade $service_name stripo/$service_name -f $service_name.yaml --namespace $NAMESPACE
        echo "-= Skip $service_name. Deployment already exist =-"
    fi
}

echo "-== Start install ==-"
helm repo update stripo
echo "Check if namespace exist"
kubectl get namespace $NAMESPACE
if [[ "$?" -ne 0 ]] ; then
    kubectl create namespace $NAMESPACE
fi
echo "Apply dockerhub secret"
kubectl apply -f secrets/docker-hub-secret.yaml -n $NAMESPACE
check_result

echo "-== Install if not exist =--"
echo -ne '#                         (2%)\r'
install_or_skip "stripo-security-service"
check_result
echo -ne '##                        (5%)\r'
install_or_skip "emple-ui"
check_result
echo -ne '###                       (10%)\r'
install_or_skip "stripo-plugin-proxy-service"
check_result
echo -ne '#####                     (23%)\r'
install_or_skip "stripo-plugin-statistics-service"
check_result
echo -ne '#######                   (31%)\r'
install_or_skip "stripo-plugin-details-service"
check_result
echo -ne '##########                (41%)\r'
install_or_skip "screenshot-service"
check_result
echo -ne '###########               (45%)\r'
install_or_skip "stripo-plugin-documents-service"
check_result
echo -ne '############              (53%)\r'
install_or_skip "stripo-plugin-image-bank-service"
check_result
echo -ne '#############             (57%)\r'
install_or_skip "stripo-plugin-custom-blocks-service"
check_result
echo -ne '##############            (60%)\r'
install_or_skip "stripe-html-gen-service"
check_result
echo -ne '###############           (69%)\r'
install_or_skip "patches-service"
check_result
echo -ne '#################         (75%)\r'
install_or_skip "amp-validator-service"
check_result
echo -ne '###################       (82%)\r'
install_or_skip "stripe-html-cleaner-service"
check_result
echo -ne '#####################     (89%)\r'
install_or_skip "stripo-plugin-api-gateway"
check_result
echo -ne '#######################    (91%)\r'
install_or_skip "stripo-plugin-details-service"
check_result
echo -ne '########################   (92%)\r'
install_or_skip "stripo-plugin-drafts-service"
check_result
echo -ne '########################## (94%)\r'
install_or_skip "emple-loadbalancer"
check_result
echo -ne '########################## (97%)\r'
install_or_skip "countdowntimer"
check_result
echo -ne '########################## (99%)\r'
install_or_skip "stripo-timer-api"
check_result
echo -ne '###########################(100%)\r'
echo "========================================"
echo "-========= Install completed ==========-"
echo "========================================"
