# Ejercicios prácticos — Sesión en directo (2h30)

Los alumnos ya han visto los 6 vídeos de teoría (`1-guion-videos-teoria.md` / `2-presentacion-kubernetes.pptx`). Esta sesión es **casi 100% práctica** sobre un cluster real.

Todos los manifiestos YAML están en la carpeta `yaml/`, listos para aplicar — no hace falta escribirlos desde cero en directo, solo explicar y lanzar.

## Antes de empezar

- **Entorno recomendado:** un playground de Kubernetes en el navegador (ver `README-entorno.md` para opciones), para no perder tiempo con instalaciones locales.
- Cada alumno necesita: acceso a una terminal con `kubectl`, y los archivos de la carpeta `yaml/` subidos o copiables.
- Si alguien tiene su propia imagen del bloque de Docker en un registro accesible (Docker Hub, etc.), que la use en vez de `nginx:1.25` / `httpd:2.4` — está indicado con un comentario en cada YAML.

---

## Agenda (150 min)

| Tiempo | Bloque |
|---|---|
| 0–10 min | Bienvenida + repaso relámpago |
| 10–25 min | Recap arquitectura + verificar acceso al cluster |
| 25–45 min | Lab 1 — Pod y Deployment |
| 45–65 min | Lab 2 — Services |
| 65–75 min | **Descanso** |
| 75–95 min | Lab 3 — ConfigMap y Secret |
| 95–110 min | Lab 4 — Probes y recursos |
| 110–125 min | Lab 5 — Escalado y rolling update |
| 125–140 min | Reto final integrador |
| 140–150 min | Cierre y siguientes pasos |

---

## 0–10 min · Repaso relámpago

Lánzalas en voz alta, que respondan a mano alzada o por chat — sirve para detectar quién no vio los vídeos:

1. ¿Qué diferencia hay entre un ReplicaSet y un Deployment?
2. ¿Qué componente del control plane decide en qué nodo va un Pod?
3. Si el liveness probe falla, ¿qué hace Kubernetes? ¿Y si falla el readiness?
4. ¿Por qué un Secret no es lo mismo que "datos cifrados"?

---

## 10–25 min · Verificar acceso al cluster

```bash
kubectl version --short
kubectl get nodes
kubectl get namespaces
```

**Checkpoint:** todos deben ver al menos un nodo en estado `Ready`. Si alguien no tiene acceso, es el momento de resolverlo, no a mitad del Lab 1.

Aprovecha para señalar en el playground/terminal, en voz alta, dónde estaría físicamente cada pieza de la arquitectura (esto es control plane, esto es el nodo).

---

## 25–45 min · Lab 1 — Pod y Deployment

**Objetivo:** ver en vivo por qué no se usan Pods sueltos.

```bash
# 1. Crear un Pod suelto
kubectl apply -f yaml/01-pod.yaml
kubectl get pods -w
```

Con el Pod corriendo, mátalo tú mismo para provocar el efecto:

```bash
kubectl delete pod web-pod
kubectl get pods
# → el Pod NO vuelve a aparecer. Nadie lo repone.
```

```bash
# 2. Ahora con Deployment
kubectl delete -f yaml/01-pod.yaml --ignore-not-found
kubectl apply -f yaml/02-deployment.yaml
kubectl get pods -l app=web-demo -w
```

Repite el experimento: borra uno de los Pods gestionados por el Deployment.

```bash
kubectl delete pod <nombre-de-un-pod>
kubectl get pods -l app=web-demo
# → aparece uno nuevo enseguida. Self-healing en acción.
```

**Checkpoint:** 3 réplicas corriendo, y borrar una hace que aparezca otra automáticamente.

---

## 45–65 min · Lab 2 — Services

**Objetivo:** exponer el Deployment sin depender de IPs de Pods.

```bash
kubectl apply -f yaml/03-service-clusterip.yaml
kubectl get svc web-service-internal
kubectl describe svc web-service-internal   # mirar "Endpoints": deben ser 3 IPs de Pods
```

Prueba de acceso interno (desde un Pod temporal dentro del cluster):

```bash
kubectl run test-curl --image=curlimages/curl -it --rm -- curl web-service-internal
```

Ahora exponlo hacia fuera:

```bash
kubectl apply -f yaml/04-service-nodeport.yaml
kubectl get svc web-service-external
# Acceder desde el navegador/curl a <IP-del-nodo>:30080 (según cómo exponga puertos tu playground)
```

**Checkpoint:** el `curl` interno devuelve la página de bienvenida de nginx; el Service muestra 3 endpoints.

---

## 65–75 min · Descanso

---

## 75–95 min · Lab 3 — ConfigMap y Secret

**Objetivo:** inyectar configuración sin tocar la imagen.

```bash
kubectl apply -f yaml/05-configmap.yaml
kubectl apply -f yaml/06-secret.yaml
kubectl apply -f yaml/07-deployment-with-config.yaml   # reemplaza el Deployment anterior
```

Verifica que las variables llegaron al contenedor:

```bash
kubectl get pods -l app=web-demo
kubectl exec -it <nombre-de-un-pod> -- env | grep -E "APP_|DB_"
```

Demuestra en vivo que el Secret no está cifrado:

```bash
kubectl get secret web-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
# → aparece "supersecreto123" en texto plano
```

**Checkpoint:** las variables `APP_ENV`, `APP_MENSAJE` y `DB_PASSWORD` aparecen dentro del contenedor.

---

## 95–110 min · Lab 4 — Probes y recursos

```bash
kubectl apply -f yaml/08-deployment-probes.yaml
kubectl get pods -l app=web-demo
kubectl describe pod <nombre-de-un-pod>   # buscar la sección "Liveness" / "Readiness" en el describe
```

Provoca un fallo de readiness a propósito (opcional, si el playground lo permite) escalando el puerto de la probe a uno que no responde, y observa que el Pod sale de los `Endpoints` del Service sin ser reiniciado:

```bash
kubectl get endpoints web-service-internal
```

**Checkpoint:** el `describe pod` muestra las probes configuradas y los `resources.requests/limits`.

---

## 110–125 min · Lab 5 — Escalado y rolling update

```bash
# Escalado manual
kubectl scale deployment web-deployment --replicas=6
kubectl get pods -l app=web-demo -w
```

```bash
# Rolling update: cambiar de versión de imagen
kubectl set image deployment/web-deployment web=nginx:1.27
kubectl rollout status deployment/web-deployment
```

```bash
# Rollback si algo sale mal
kubectl rollout undo deployment/web-deployment
kubectl rollout history deployment/web-deployment
```

**Checkpoint:** durante el `rollout status`, el número de Pods disponibles nunca llega a 0 — cero downtime.

---

## 125–140 min · Reto final integrador

**Objetivo:** montar una mini-app de dos componentes usando todo lo visto: Deployment, Service, ConfigMap, probes, resources, y comunicación entre servicios por DNS interno.

Los archivos ya están en `yaml/reto-final/`. En grupos de 2-3, que los alumnos:

1. Apliquen los 3 manifiestos:
   ```bash
   kubectl apply -f yaml/reto-final/backend-configmap.yaml
   kubectl apply -f yaml/reto-final/backend-deployment.yaml
   kubectl apply -f yaml/reto-final/frontend.yaml
   ```
2. Verifiquen que el `frontend` puede resolver `backend-service` por DNS interno:
   ```bash
   kubectl exec -it <pod-frontend> -- getent hosts backend-service
   ```
3. **Reto extra** (si sobra tiempo): que añadan un `HorizontalPodAutoscaler` al backend usando `yaml/09-hpa.yaml` como plantilla.

**Checkpoint de cierre del reto:** cada grupo debe poder explicar, señalando su propio despliegue, qué pieza de Kubernetes resuelve qué problema (esto conecta directamente con el vídeo 1).

---

## 140–150 min · Cierre

- Repaso de 1 minuto: de "un `docker run` en un servidor" a "un sistema que se autorrepara, escala y se actualiza solo".
- Siguiente paso natural del máster: **Helm** (empaquetar estos mismos YAML como plantillas reutilizables) y **GitOps** (Argo CD / Flux) para que los cambios se desplieguen automáticamente desde un repositorio Git.
- Recordar limpiar el cluster si el playground lo requiere:
  ```bash
  kubectl delete deployment,service,configmap,secret,hpa --all
  ```

---

## Troubleshooting rápido para el profesor

| Síntoma | Causa probable | Solución |
|---|---|---|
| `Pod` en `Pending` | No hay recursos suficientes en el nodo, o `requests` demasiado altos | `kubectl describe pod <nombre>` → sección Events |
| `Pod` en `ImagePullBackOff` | Imagen no existe o registro privado sin credenciales | Revisar el nombre de la imagen; usar `nginx:1.25` como fallback |
| `Service` sin `Endpoints` | El `selector` del Service no coincide con las `labels` del Pod | Comparar `kubectl get pods --show-labels` contra el `selector` del Service |
| `curl` interno no responde | Probando desde fuera del cluster contra un ClusterIP | Recordar: ClusterIP solo es accesible desde dentro |
| Rolling update se queda colgado | La imagen nueva no arranca (readiness nunca pasa) | `kubectl rollout undo` y revisar `kubectl describe pod` |
