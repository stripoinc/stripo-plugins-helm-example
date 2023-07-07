TAGS='esputnik/stripo-security-service:20230627-1200_07ad404
esputnik/patches-service:20230630-0732_568c0cf
esputnik/amp-validator-service:20230630-0733_568c0cf
esputnik/stripo-plugin-details-service:20230630-0738_568c0cf
esputnik/stripo-timer-api:20230630-0748_568c0cf
esputnik/stripo-plugin-drafts-service:20230703-0929_33c155e
esputnik/stripe-html-cleaner-service:20230703-0932_33c155e
esputnik/stripo-plugin-statistics-service:20230703-0933_33c155e
esputnik/stripo-plugin-proxy-service:20230703-0933_33c155e
esputnik/stripo-plugin-custom-blocks-service:20230703-0936_33c155e
esputnik/stripo-plugin-image-bank-service:20230703-0937_33c155e
esputnik/stripe-html-gen-service:20230703-0944_33c155e
stripo/ai-service:20230703-0949_33c155e
esputnik/stripo-plugin-documents-service:20230703-1451_666a685
esputnik/stripo-plugin-third-party-test-service:20230703-1451_666a685
esputnik/emple-ui:20230705-0946_8a8d9c8
esputnik/screenshot-service:20230705-1240_74d12b1
esputnik/stripo-plugin-api-gateway:20230705-1246_74d12b1
'

APPS='stripo-security-service
emple-ui
stripo-plugin-proxy-service
stripo-plugin-statistics-service
stripo-plugin-details-service
ai-service
screenshot-service
stripo-plugin-documents-service
stripo-plugin-image-bank-service
stripo-plugin-custom-blocks-service
stripe-html-gen-service
patches-service
amp-validator-service
stripe-html-cleaner-service
stripo-plugin-api-gateway
stripo-plugin-details-service
stripo-plugin-drafts-service
countdowntimer
stripo-timer-api
'


for APP in $APPS
do
    TAG=$(echo "$TAGS" | grep $APP | awk -F':' '{print $2}')
    cat $APP.yaml | sed "s|\"latest\"|\"$TAG\"|g" > $APP.yaml.new
    mv $APP.yaml.new $APP.yaml
done