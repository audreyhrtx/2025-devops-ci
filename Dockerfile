# Étape 1 : Build de l'application
# Use Debian-based image for the build stage to avoid native/binary incompatibilities
FROM node:20-bullseye AS builder
WORKDIR /app

# Copier uniquement les fichiers nécessaires pour installer les dépendances
COPY pnpm-lock.yaml package.json ./

# Use Corepack (recommended with Node >=18) to activate pnpm; fallback to npm global install if needed
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install dependencies with frozen lockfile to keep reproducible builds
RUN pnpm install --frozen-lockfile

# Copier le reste du code et builder l’application
COPY . .

# Run the build and capture logs to help debugging if it fails
RUN /bin/sh -c "pnpm build > build.log 2>&1 || (echo '--- BUILD LOG START ---' && tail -n 500 build.log && echo '--- BUILD LOG END ---' && false)"

# Étape 2 : Image finale, légère et sécurisée
FROM node:20-alpine
WORKDIR /app

# Copier uniquement les fichiers essentiels depuis le builder (built assets + node_modules)
COPY --from=builder /app /app

# Créer un utilisateur non-root
RUN addgroup -S audrey && adduser -S audrey -G audrey
USER audrey

EXPOSE 3000
CMD ["pnpm", "start"]
