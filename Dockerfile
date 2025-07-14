FROM cirrusci/flutter:stable

WORKDIR /app
COPY . .

RUN flutter pub get

CMD ["flutter", "run", "--no-sound-null-safety", "bin/scheduler.dart"]
