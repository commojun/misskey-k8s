.PHONY: config

pods:
	kubectl get pods --watch

config:
	scp config/default.yml pi41:/home/commojun/nfs/misskey/config/default.yml

secret:
	-kubectl delete secret misskey-secret
	kubectl create secret generic \
		--save-config misskey-secret \
		--from-env-file ./envfile

logs/%:
	kubectl logs --timestamps=true --prefix=true -f -l app=$*

logs-all:
	kubectl logs --timestamps=true --prefix=true -f -l app

shell/%:
	kubectl exec -it $* -- bash
