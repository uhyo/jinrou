# Dockerfile to run jinrou in a docker container.
FROM node:8
MAINTAINER uhyo
# define work directory
WORKDIR /jinrou
# First, install dependencies.
COPY ./package.json ./package-lock.json ./
RUN npm install --production
# copy source files.
COPY ./prizedata ./prizedata/
COPY ./public ./public/
COPY ./app.js ./
COPY ./client ./client/
COPY ./server ./server/
COPY ./language ./language/
# specify user to run the app.
USER node
# define command.
CMD ["node", "app.js"]
