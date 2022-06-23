FROM python:3.7-slim-buster

RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

RUN apt-get update -y && apt-get install curl libicu-dev postgresql-client libpq-dev gcc netcat procps -y