.PHONY: config

pods:
	kubectl get pods -o wide --watch

config:
	scp config/default.yml pi41:/home/commojun/nfs/misskey/config/default.yml

secret:
	-kubectl delete secret misskey-secret
	kubectl create secret generic \
		--save-config misskey-secret \
		--from-env-file ./envfile

logs/%:
	kubectl logs --timestamps=true --prefix=true --max-log-requests=9999 --ignore-errors -f -l app=$*

logs-all:
	kubectl logs --timestamps=true --prefix=true --max-log-requests=9999 --ignore-errors --prefix=true -f -l app

shell/%:
	kubectl exec -it $* -- bash

clean:
	kubectl delete pods --field-selector=status.phase=Failed
