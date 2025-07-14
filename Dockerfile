FROM cirrusci/flutter:latest

WORKDIR /app
COPY . .

RUN flutter config --enable-web
RUN flutter pub get

CMD ["flutter", "run", "-d", "web-server", "--no-sound-null-safety", "bin/scheduler.dart"]
