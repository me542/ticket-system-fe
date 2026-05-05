# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Cache dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source + .env
COPY . .

# Build using your .env values
RUN flutter build web --release --dart-define-from-file=.env

# Stage 2: Serve via Nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]