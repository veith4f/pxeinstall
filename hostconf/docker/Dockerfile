FROM tiangolo/uvicorn-gunicorn-fastapi:python3.11

RUN mkdir -p /home/hostconf && \
	addgroup --system hostconf && \
	adduser --system --group hostconf

WORKDIR /home/hostconf/app

COPY app/requirements.txt requirements.txt

RUN pip install -r requirements.txt && \
	chown -R hostconf:hostconf /home/hostconf

USER hostconf
