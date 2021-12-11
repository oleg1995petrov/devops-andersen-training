FROM python:3.6-alpine AS py_builder
WORKDIR /build
COPY . .
RUN apk update \
    && apk --no-cache add \
       zlib-dev \
       musl-dev \
       gcc \
       scons \
       patchelf \
       upx \
    && pip install --upgrade pip --no-cache-dir staticx -r requirements.txt \
    && PYTHONOPTIMIZE=1 pyinstaller -a --clean --upx-dir=/usr/bin/ -F flask_app.py \
    && staticx --strip /build/dist/flask_app /build/app \
    && mkdir /build/tmp

FROM scratch
EXPOSE 5000
COPY --from=py_builder /build/tmp /tmp
COPY --from=py_builder /build/app /
CMD ["./app"]
