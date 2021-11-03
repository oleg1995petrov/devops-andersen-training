FROM python:3.6-alpine AS py_builder
WORKDIR /test
COPY . .
RUN apk update \
    && apk --no-cache add \
       zlib-dev \
       musl-dev \
       gcc \
       scons \
       upx \
       patchelf \
    && pip install --no-cache-dir \
       flask==1.0.4 \
       emoji==1.2.0 \
       staticx \
       pyinstaller \
    && PYTHONOPTIMIZE=1 pyinstaller \
       -a --clean --upx-dir=/usr/bin/ \
       --add-data "templates/:templates/" \
       --add-data "static/:static/" \
       --add-data "services.py:services.py" \
       -F app.py \
    && staticx --strip /test/dist/app /test/app \
    && mkdir /test/tmp

FROM scratch
COPY --from=py_builder /test/tmp /tmp
COPY --from=py_builder /test/app /
EXPOSE 5000
CMD ["./app"]  
