FROM node:16-alpine3.15 as builder

WORKDIR /usr/app
RUN npm install -g pnpm

COPY package.json .
COPY pnpm-lock.yaml .
COPY pnpm-workspace.yaml .

COPY . .

# install dependencies
RUN pnpm install --frozen-lockfile

# generate prisma-client-js
RUN pnpm run db:generate

# compile ts to js and minify
RUN pnpm run build

# prune all unnecessary modules
RUN pnpm prune --production

# * ====================
FROM node:16-alpine3.15 as main

WORKDIR /usr/app/

COPY --from=builder /usr/app/node_modules node_modules
COPY --from=builder /usr/app/prisma/ prisma/
COPY --from=builder /usr/app/dist dist
COPY --from=builder /usr/app/script script

ENV NODE_ENV production

CMD ["./script/docker-entrypoint.sh"]

EXPOSE 8080
