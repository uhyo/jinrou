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
COPY ./manual ./manual/
COPY ./client ./client/
COPY ./server ./server/
COPY ./language ./language/
# expose to webserver.
VOLUME ["/jinrou/client/static/", "/jinrou/public/"]
# specify user to run the app.
USER node
# expose default port.
EXPOSE 8800
# define command.
CMD ["node", "app.js"]
