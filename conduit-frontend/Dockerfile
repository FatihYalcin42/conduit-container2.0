FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:1.27-alpine

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /docker-entrypoint.d/40-generate-env.sh
COPY --from=build /app/dist/angular-conduit /usr/share/nginx/html

RUN chmod +x /docker-entrypoint.d/40-generate-env.sh

EXPOSE 8282
