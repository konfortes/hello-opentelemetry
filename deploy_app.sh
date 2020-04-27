kubectl create namespace app

echo "bulding app"
docker build -t telemetry-app:latest -f app/Dockerfile app

echo "deploying app"
kubectl -n app apply -f app/deployment.yaml
kubectl -n app delete pod -l app=telemetry-app