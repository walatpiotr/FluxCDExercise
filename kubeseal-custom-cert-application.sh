
export CLUSTER_DIRECTORY="clusters/local"
export PRIVATEKEY="mytls.key"
export PUBLICKEY="mytls.crt"
export NAMESPACE="kubeseal"
export SECRETNAME="mycustomkeys"
export PRE_CHANGE_SECRET_PATH="previous-secret.yaml"
export PREVIOUS_CERT=""
### Functions

create_certs () {
    openssl req -x509 -days 365 -nodes \
        -newkey rsa:4096 \
        -keyout "$PRIVATEKEY" \
        -out "$PUBLICKEY" \
        -subj "/CN=sealed-secret/O=sealed-secret"
}

update_secrets_with_certs () {
    kubectl -n "$NAMESPACE" get secret "$SECRETNAME" -o yaml --ignore-not-found=true > $PRE_CHANGE_SECRET_PATH

    kubectl -n "$NAMESPACE" delete secret "$SECRETNAME" --ignore-not-found=true

    kubectl -n "$NAMESPACE" create secret tls "$SECRETNAME" \
        --cert="$PUBLICKEY" \
        --key="$PRIVATEKEY"

    kubectl -n "$NAMESPACE" label secret "$SECRETNAME" \
        sealedsecrets.bitnami.com/sealed-secrets-key=active

    kubectl -n "$NAMESPACE" rollout restart deployment/sealed-secrets-controller
    
    kubectl -n "$NAMESPACE" rollout status deployment/sealed-secrets-controller
    
    sleep 10
    
    kubectl -n "$NAMESPACE" logs deployment/sealed-secrets-controller
}

cleanup () {
    rm $PRIVATEKEY
    rm $PRE_CHANGE_SECRET_PATH
}

decode () {

}

encode () {
    
}

### Script

set -x 
pushd $CLUSTER_DIRECTORY
(create_certs && update_secrets_with_certs)
export PREVIOUS_CERT=$(yq eval '.data."tls.crt"' $PRE_CHANGE_SECRET_PATH)
decode
encode
cleanup
popd
